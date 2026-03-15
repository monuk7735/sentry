//
//  View+Shortcut.swift
//  Sentry
//
//  Created by Monu Kumar on 12/03/26.
//

import SwiftUI

extension View {
    @ViewBuilder
    func shortcutFromConfig(_ config: ShortcutConfig?) -> some View {
        if let config, let key = config.keyEquivalent {
            self.keyboardShortcut(key, modifiers: config.swiftUIModifiers)
        } else {
            self
        }
    }
}
