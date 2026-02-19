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
    
    private init() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(systemScreenDidLock),
            name: Notification.Name("com.apple.screenIsLocked"),
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
        guard isLocked else { return }
        
        self.refreshWindows(killAll: true)
    }
    
    @objc private func systemScreenDidLock() {
        self.invalidateAuthContext()
        self.unlock()
    }
    
    @objc private func windowDidBecomeKey(_ notification: Notification) {
        guard isLocked, !isStarting else { return }
        
        self.invalidateAuthContext()
        
        DispatchQueue.main.async { [weak self] in
            self?.authenticate()
        }
    }
    
    private func invalidateAuthContext() {
        self.authContext?.invalidate()
        self.authContext = nil
    }
    
    private func createPanel(for screen: NSScreen) -> NSPanel {
        let panel = LockPanel(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.backgroundColor = .black
        panel.isOpaque = true
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.hidesOnDeactivate = false
        
        let hostingView = NSHostingView(rootView: LockView())
        panel.contentView = hostingView
        panel.contentView?.wantsLayer = true
        
        if let layer = panel.contentView?.layer {
            let center = CGPoint(x: panel.frame.width / 2, y: panel.frame.height / 2)
            layer.position = center
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        }
        
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
        
        NSScreen.screens.forEach { screen in
            var panel: NSWindow! = windows[screen]
            
            if panel == nil {
                panel = createPanel(for: screen)
            }
            
            #if DEBUG
            panel.setFrame(screen.frame.insetBy(dx: screen.frame.width * 0.4, dy: screen.frame.height * 0.4), display: true)
            #else
            panel.setFrame(screen.frame, display: true)
            #endif
            
            panel.orderFrontRegardless()
            
            windows[screen] = panel
            
            WindowManager.shared?.moveToLockScreen(panel)
        }
    }
    
    func lock() {
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
    
    func unlock() {
        guard isLocked else { return }
        
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
    
    private func finishUnlock() {
        if let activity = lockActivity {
            ProcessInfo.processInfo.endActivity(activity)
            self.lockActivity = nil
        }
        
        NSApp.presentationOptions = []
        
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
            if caffeineActivity == nil {
                caffeineActivity = ProcessInfo.processInfo.beginActivity(
                    options: [.idleDisplaySleepDisabled, .idleSystemSleepDisabled],
                    reason: "Sentry Caffeine Mode"
                )
            }
        } else {
            if let activity = caffeineActivity {
                ProcessInfo.processInfo.endActivity(activity)
                caffeineActivity = nil
            }
        }
    }
    
}

class LockPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
