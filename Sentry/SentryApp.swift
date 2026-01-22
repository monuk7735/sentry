//
//  SentryApp.swift
//  Sentry
//
//  Created by Monu Kumar on 06/01/26.
//

import SwiftUI

@main
struct SentryApp: App {
    
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
    }
    
    var body: some Scene {
        MenuBarExtra(
            content: {
                Text("Sentry")
                
                Divider()
                
                Button("Activate") {
                    lockManager.lock()
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                
                Button(
                    action: {
                        lockManager.caffeineMode.toggle()
                    }
                ) {
                    Toggle("Caffeine", isOn: $lockManager.caffeineMode)
                        .toggleStyle(.checkbox)
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                
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
