//
//  SettingsView.swift
//  Sentry
//
//  Created by Monu Kumar on 12/03/26.
//

import SwiftUI

struct SettingsView: View {

    @State private var lockShortcut: ShortcutConfig? = ShortcutHelper.loadIfSet(forKey: .lock)
    @State private var caffeineShortcut: ShortcutConfig? = ShortcutHelper.loadIfSet(forKey: .caffeine)

    var body: some View {
        Form {
            Section {
                LabeledContent("Lock Screen") {
                    ShortcutRecorderView(shortcut: $lockShortcut)
                }

                LabeledContent("Caffeine Mode") {
                    ShortcutRecorderView(shortcut: $caffeineShortcut)
                }
            } header: {
                HStack {
                    Text("Keyboard Shortcuts")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Reset to Defaults") {
                        ShortcutHelper.resetAll()
                        lockShortcut     = ShortcutHelper.getDefault(forKey: .lock)
                        caffeineShortcut = ShortcutHelper.getDefault(forKey: .caffeine)
                    }
                }
            } footer: {
                Text("Click a field and press your desired key combination.\nPress Escape to cancel. Press x to clear.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)
        }
        .formStyle(.grouped)
        .padding(8)
        .padding(.horizontal, 4)
        .frame(
            minWidth: 600,
            minHeight: 300
        )
        .onChange(of: lockShortcut) { newValue in
            if let shortcut = newValue {
                ShortcutHelper.save(shortcut, forKey: .lock)
            } else {
                ShortcutHelper.reset(forKey: .lock)
            }
            HotKeyManager.shared.reloadShortcuts()
        }
        .onChange(of: caffeineShortcut) { newValue in
            if let shortcut = newValue {
                ShortcutHelper.save(shortcut, forKey: .caffeine)
            } else {
                ShortcutHelper.reset(forKey: .caffeine)
            }
            HotKeyManager.shared.reloadShortcuts()
        }
    }
}

#Preview {
    SettingsView()
}
