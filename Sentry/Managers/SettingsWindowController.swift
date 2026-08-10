//
//  SettingsWindowController.swift
//  Sentry
//
//  Created by Monu Kumar on 12/03/26.
//

import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {

    convenience init() {
        let hostingController = NSHostingController(rootView: SettingsView())
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 540),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Sentry Settings"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.contentViewController = hostingController
        window.setContentSize(NSSize(width: 680, height: 540))
        window.center()

        self.init(window: window)
    }

    func show() {
        window?.center()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.orderFrontRegardless()
        window?.makeKeyAndOrderFront(nil)
    }
    
    func closeWindow() {
        window?.close()
    }
}

final class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    
    private var controller: SettingsWindowController?
    
    private init() {}
    
    func show(tab: SettingsTab = .shortcuts) {
        DispatchQueue.main.async {
            SettingsManager.shared.selectedTab = tab
            if self.controller == nil {
                self.controller = SettingsWindowController()
            }
            self.controller?.show()
        }
    }
    
    func close() {
        DispatchQueue.main.async {
            self.controller?.closeWindow()
        }
    }
}
