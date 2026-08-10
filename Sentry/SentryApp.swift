//
//  SentryApp.swift
//  Sentry
//
//  Created by Monu Kumar on 06/01/26.
//

import SwiftUI

@main
struct SentryApp: App {
    
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var lockManager = LockManager.shared
    private let hotKeyManager = HotKeyManager.shared

    init() {
        hotKeyManager.onLockHotKey = {
            DispatchQueue.main.async {
                LockManager.shared.lock()
            }
        }
        
        hotKeyManager.onCaffeineHotKey = {
            DispatchQueue.main.async {
                LockManager.shared.caffeineMode.toggle()
            }
        }
        
        #if DEBUG
        let showWelcomeOnLaunch = true
        #else
        let showWelcomeOnLaunch = !UserDefaults.standard.bool(forKey: "hasSeenWelcome")
        #endif
        
        if showWelcomeOnLaunch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                WelcomeWindowManager.shared.show()
            }
        }
    }
    
    var body: some Scene {
        MenuBarExtra(
            content: {
                Text("Sentry")
                
                Divider()
                
                Button("Lock Screen") {
                    lockManager.lock()
                }
                .shortcutFromConfig(ShortcutHelper.loadIfSet(forKey: .lock))

                Button(
                    action: {
                        lockManager.caffeineMode.toggle()
                    }
                ) {
                    Toggle("Caffeine Mode", isOn: $lockManager.caffeineMode)
                }
                .shortcutFromConfig(ShortcutHelper.loadIfSet(forKey: .caffeine))

                Divider()

                Button("Welcome Guide") {
                    WelcomeWindowManager.shared.show()
                }

                Button("Settings") {
                    SettingsWindowManager.shared.show()
                }
                .keyboardShortcut(",", modifiers: .command)

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        ) {
            if lockManager.caffeineMode, let image = NSImage(named: "Sentry") {
                Image(nsImage: image.tinted(with: .systemOrange))
                    .renderingMode(.original)
            } else {
                Image("Sentry")
                    .renderingMode(.template)
            }
        }
    }
}
