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
        let window = NSWindow(contentViewController: hostingController)
        
        window.title = "Sentry Settings"
        window.styleMask = [.titled, .closable, .resizable, .utilityWindow]
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
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
}
