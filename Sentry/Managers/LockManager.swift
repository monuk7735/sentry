//
//  LockManager.swift
//  Sentry
//
//  Created by Monu Kumar on 06/01/26.
//

import Cocoa
import LocalAuthentication
import SwiftUI
import Combine
import IOKit
import IOKit.pwr_mgt

class LockManager: ObservableObject {
    
    static let shared = LockManager()
    
    @Published var isLocked = false
    @Published var canUseTouchID = false
    @Published var caffeineMode = false {
        didSet {
            updateCaffeineState()
        }
    }
    
    private var windows: [NSScreen: NSWindow] = [:]
    private var lockActivity: NSObjectProtocol?
    private var caffeineActivity: NSObjectProtocol?
    
    private var authContext: LAContext?
    
    private var isStarting = false
    
    private var lockAssertionID: IOPMAssertionID = 0
    private var caffeineAssertionID: IOPMAssertionID = 0
    
    private init() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(systemScreenDidLock),
            name: Notification.Name("com.apple.screenIsLocked"),
            object: nil
        )
        
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(systemScreenDidUnlock),
            name: Notification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
    }
    
    @objc private func screenParametersDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isLocked else { return }
            self.refreshWindows(killAll: true)
        }
    }
    
    @objc private func systemScreenDidLock() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if SettingsManager.shared.lockBehavior == .system {
                guard !self.isLocked else { return }
                self.isLocked = true
                
                // Delay window presentation to ensure macOS lockscreen transition has fully finished
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                    guard let self = self, self.isLocked else { return }
                    
                    if self.lockAssertionID == 0 {
                        self.lockAssertionID = self.createAssertion(
                            type: kIOPMAssertionTypeNoDisplaySleep,
                            reason: "Sentry Lock Screen"
                        )
                    }
                    
                    self.refreshWindows(killAll: true)
                }
            } else {
                self.invalidateAuthContext()
                self.unlock()
            }
        }
    }
    
    @objc private func systemScreenDidUnlock() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if SettingsManager.shared.lockBehavior == .system {
                self.unlock()
            }
        }
    }
    
    @objc private func windowDidBecomeKey(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isLocked, !self.isStarting else { return }
            if SettingsManager.shared.lockBehavior == .custom {
                self.invalidateAuthContext()
                self.authenticate()
            }
        }
    }
    
    private func invalidateAuthContext() {
        self.authContext?.invalidate()
        self.authContext = nil
    }
    
    private func createPanel(for screen: NSScreen) -> NSPanel {
        let isSystem = SettingsManager.shared.lockBehavior == .system
        let frame: NSRect
        if isSystem {
            frame = screen.frame.insetBy(dx: screen.frame.width * 0.2, dy: screen.frame.height * 0.2)
        } else {
            frame = screen.frame
        }
        
        let panel = LockPanel(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.backgroundColor = isSystem ? .clear : .black
        panel.isOpaque = !isSystem
        panel.hasShadow = false
        panel.ignoresMouseEvents = isSystem
        panel.hidesOnDeactivate = false
        
        let hostingView = NSHostingView(rootView: LockView())
        panel.contentView = hostingView
        
        return panel
    }
    
    private func refreshWindows(killAll: Bool = false) {
        windows.forEach { screen, window in
            if killAll || !NSScreen.screens.contains(
                where: { $0 == screen}
            ) {
                window.close()
                
                windows.removeValue(
                    forKey: screen
                )
            }
        }
        
        let isSystem = SettingsManager.shared.lockBehavior == .system
        NSScreen.screens.forEach { screen in
            var panel: NSWindow! = windows[screen]
            
            if panel == nil {
                panel = createPanel(for: screen)
            }
            
            let frame = isSystem ? screen.frame.insetBy(dx: screen.frame.width * 0.2, dy: screen.frame.height * 0.2) : screen.frame
            panel.setFrame(frame, display: true)
            
            panel.orderFrontRegardless()
            
            windows[screen] = panel
            
            WindowManager.shared?.moveToLockScreen(panel)
        }
    }
    
    func lock() {
        guard !isLocked else { return }
        
        if SettingsManager.shared.lockBehavior == .system {
            lockmacOS()
        } else {
            checkBiometricAvailability()
            
            // Start lock activity if not already active or if separate from caffeine
            if lockActivity == nil {
                lockActivity = ProcessInfo.processInfo.beginActivity(
                    options: [.idleDisplaySleepDisabled, .idleSystemSleepDisabled],
                    reason: "Sentry Lock Screen"
                )
            }
            
            let options: NSApplication.PresentationOptions = [
                .hideDock,
                .hideMenuBar,
                .disableProcessSwitching,
                .disableForceQuit,
                .disableSessionTermination,
                .disableHideApplication
            ]
            NSApp.presentationOptions = options
            NSApp.activate(ignoringOtherApps: true)
            
            self.refreshWindows(killAll: true)
            
            for window in windows.values {
                window.alphaValue = 0
                
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.5
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    window.animator().alphaValue = 1
                }
            }
            
            isLocked = true
            isStarting = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.authenticate()
                self?.isStarting = false
            }
        }
    }
    
    func lockmacOS() {
        let frameworkPath = "/System/Library/PrivateFrameworks/login.framework/login"
        if let handle = dlopen(frameworkPath, RTLD_LAZY) {
            if let symbol = dlsym(handle, "SACLockScreenImmediate") {
                typealias LockScreenFunction = @convention(c) () -> Int32
                let sacLockScreenImmediate = unsafeBitCast(symbol, to: LockScreenFunction.self)
                _ = sacLockScreenImmediate()
            }
            dlclose(handle)
        } else {
            // Fallback: Open ScreenSaverEngine
            let process = Process()
            process.launchPath = "/usr/bin/open"
            process.arguments = ["/System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app"]
            try? process.run()
        }
    }
    
    func unlock() {
        guard isLocked else { return }
        
        if SettingsManager.shared.lockBehavior == .system {
            self.finishUnlock()
        } else {
            self.invalidateAuthContext()
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                for window in windows.values {
                    window.animator().alphaValue = 0
                }
            } completionHandler: { [weak self] in
                self?.finishUnlock()
            }
        }
    }
    
    private func finishUnlock() {
        if SettingsManager.shared.lockBehavior == .system {
            self.releaseAssertion(&self.lockAssertionID)
        } else {
            if let activity = lockActivity {
                ProcessInfo.processInfo.endActivity(activity)
                self.lockActivity = nil
            }
            NSApp.presentationOptions = []
        }
        
        windows.values.forEach { $0.close() }
        windows.removeAll()
        
        isLocked = false
    }
    
    func authenticate() {
        let context = LAContext()
        self.invalidateAuthContext()
        self.authContext = context
        var error: NSError?
        
        let reason = "Unlock to access your Mac"
        
        let completion: (Bool, Error?) -> Void = { [weak self] success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    self?.unlock()
                }
            }
        }
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason, reply: completion)
        } else {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason, reply: completion)
        }
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        DispatchQueue.main.async {
            self.canUseTouchID = available
        }
    }
    
    private func updateCaffeineState() {
        if caffeineMode {
            if caffeineAssertionID == 0 {
                caffeineAssertionID = createAssertion(
                    type: kIOPMAssertionTypeNoDisplaySleep,
                    reason: "Sentry Caffeine Mode"
                )
            }
        } else {
            releaseAssertion(&caffeineAssertionID)
        }
    }
    
    private func createAssertion(type: String, reason: String) -> IOPMAssertionID {
        var assertionID: IOPMAssertionID = 0
        let success = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )
        return success == kIOReturnSuccess ? assertionID : 0
    }
    
    private func releaseAssertion(_ assertionID: inout IOPMAssertionID) {
        guard assertionID != 0 else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
    }
    
}

class LockPanel: NSPanel {
    override var canBecomeKey: Bool {
        return SettingsManager.shared.lockBehavior == .custom
    }
    override var canBecomeMain: Bool {
        return SettingsManager.shared.lockBehavior == .custom
    }
}
