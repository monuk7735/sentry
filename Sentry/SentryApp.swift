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
    
    var body: some Scene {
        MenuBarExtra("Sentry", systemImage: "lock.shield") {
            Button("Activate") {
                lockManager.lock()
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
