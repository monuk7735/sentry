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
    
    private var screenWindows: [NSScreen: NSPanel] = [:]
    private var lockActivity: NSObjectProtocol?
    private var caffeineActivity: NSObjectProtocol?
    
    private var authContext: LAContext?
    private var isAuthenticating = false
    
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
        updateOverlays()
    }
    
    @objc private func systemScreenDidLock() {
        authContext?.invalidate()
        
        if isLocked {
            unlock()
        }
    }
    
    @objc private func windowDidBecomeKey(_ notification: Notification) {
        guard isLocked, !isStarting else { return }
        
        authContext?.invalidate()
        isAuthenticating = false
        
        DispatchQueue.main.async { [weak self] in
            self?.authenticate()
        }
    }
    
    func lock() {
        guard !isLocked else { return }
        
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
        
        updateOverlays()
        
        for window in screenWindows.values {
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
        
        authContext?.invalidate()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            for window in screenWindows.values {
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
        
        screenWindows.values.forEach { $0.close() }
        screenWindows.removeAll()
        
        isLocked = false
    }
    
    func authenticate() {
        guard !isAuthenticating else { return }
        
        let context = LAContext()
        self.authContext = context
        self.isAuthenticating = true
        var error: NSError?
        
        let reason = "Unlock to access your Mac"
        
        let completion: (Bool, Error?) -> Void = { [weak self] success, authenticationError in
            DispatchQueue.main.async {
                self?.isAuthenticating = false
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
    
    private func updateOverlays() {
        let screens = NSScreen.screens
        
        for screen in screens {
            if let existingWindow = screenWindows[screen] {
                existingWindow.setFrame(screen.frame, display: true)
                existingWindow.orderFrontRegardless()
            } else {
                let panel = createPanel(for: screen)
                screenWindows[screen] = panel
                
                WindowManager.shared?.moveToLockScreen(panel)
                panel.orderFrontRegardless()
                
                if isLocked {
                    panel.alphaValue = 1
                }
            }
        }
        
        for (oldScreen, window) in screenWindows {
            if !screens.contains(oldScreen) {
                window.close()
                screenWindows.removeValue(forKey: oldScreen)
            }
        }
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
        
        panel.contentView?.wantsLayer = true
        
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .withinWindow
        visualEffect.state = .active
        visualEffect.material = .fullScreenUI
        
        let hostingView = NSHostingView(rootView: LockView())
        panel.contentView = hostingView
        panel.contentView?.wantsLayer = true
        
        panel.setFrame(screen.frame, display: true)
        
        if let layer = panel.contentView?.layer {
            let center = CGPoint(x: panel.frame.width / 2, y: panel.frame.height / 2)
            layer.position = center
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        }
        
        return panel
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
