//
//  WelcomeWindowController.swift
//  Sentry
//
//  Created by Monu Kumar on 10/08/26.
//

import AppKit
import SwiftUI

final class WelcomeWindowController: NSWindowController {

    convenience init() {
        let hostingController = NSHostingController(rootView: WelcomeView())
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Welcome to Sentry"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.contentViewController = hostingController
        window.setContentSize(NSSize(width: 680, height: 500))
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

final class WelcomeWindowManager {
    static let shared = WelcomeWindowManager()
    
    private var controller: WelcomeWindowController?
    
    private init() {}
    
    func show() {
        DispatchQueue.main.async {
            if self.controller == nil {
                self.controller = WelcomeWindowController()
            }
            self.controller?.show()
        }
    }
    
    func close() {
        DispatchQueue.main.async {
            self.controller?.closeWindow()
        }
    }
    
    func bringToFrontIfOpen() {
        DispatchQueue.main.async {
            if let window = self.controller?.window, window.isVisible {
                NSApp.activate(ignoringOtherApps: true)
                window.orderFrontRegardless()
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}
