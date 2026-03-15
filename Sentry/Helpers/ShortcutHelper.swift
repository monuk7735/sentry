//
//  ShortcutHelper.swift
//  Sentry
//
//  Created by Monu Kumar on 12/03/26.
//

import Carbon
import AppKit
import SwiftUI

struct ShortcutConfig: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let defaultLock = ShortcutConfig(
        keyCode: UInt32(kVK_ANSI_L),
        modifiers: UInt32(optionKey | shiftKey)
    )

    static let defaultCaffeine = ShortcutConfig(
        keyCode: UInt32(kVK_ANSI_K),
        modifiers: UInt32(optionKey | shiftKey)
    )

    var displayString: String {
        var parts = ""
        if modifiers & UInt32(controlKey) != 0 { parts += "⌃" }
        if modifiers & UInt32(optionKey)  != 0 { parts += "⌥" }
        if modifiers & UInt32(shiftKey)   != 0 { parts += "⇧" }
        if modifiers & UInt32(cmdKey)     != 0 { parts += "⌘" }
        if let char = keyCodeToChar(keyCode) { parts += char.uppercased() }
        return parts
    }

    var keyEquivalent: KeyEquivalent? {
        guard let char = keyCodeToChar(keyCode),
              let scalar = char.unicodeScalars.first else { return nil }
        return KeyEquivalent(Character(scalar))
    }

    var swiftUIModifiers: SwiftUI.EventModifiers {
        var mods: SwiftUI.EventModifiers = []
        if modifiers & UInt32(cmdKey)     != 0 { mods.insert(.command) }
        if modifiers & UInt32(shiftKey)   != 0 { mods.insert(.shift) }
        if modifiers & UInt32(optionKey)  != 0 { mods.insert(.option) }
        if modifiers & UInt32(controlKey) != 0 { mods.insert(.control) }
        return mods
    }

    var nsModifiers: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if modifiers & UInt32(cmdKey)     != 0 { flags.insert(.command) }
        if modifiers & UInt32(shiftKey)   != 0 { flags.insert(.shift) }
        if modifiers & UInt32(optionKey)  != 0 { flags.insert(.option) }
        if modifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        return flags
    }

    func keyCodeToChar(_ keyCode: UInt32) -> String? {
        let map: [UInt32: String] = [
            UInt32(kVK_ANSI_A): "a", UInt32(kVK_ANSI_B): "b", UInt32(kVK_ANSI_C): "c",
            UInt32(kVK_ANSI_D): "d", UInt32(kVK_ANSI_E): "e", UInt32(kVK_ANSI_F): "f",
            UInt32(kVK_ANSI_G): "g", UInt32(kVK_ANSI_H): "h", UInt32(kVK_ANSI_I): "i",
            UInt32(kVK_ANSI_J): "j", UInt32(kVK_ANSI_K): "k", UInt32(kVK_ANSI_L): "l",
            UInt32(kVK_ANSI_M): "m", UInt32(kVK_ANSI_N): "n", UInt32(kVK_ANSI_O): "o",
            UInt32(kVK_ANSI_P): "p", UInt32(kVK_ANSI_Q): "q", UInt32(kVK_ANSI_R): "r",
            UInt32(kVK_ANSI_S): "s", UInt32(kVK_ANSI_T): "t", UInt32(kVK_ANSI_U): "u",
            UInt32(kVK_ANSI_V): "v", UInt32(kVK_ANSI_W): "w", UInt32(kVK_ANSI_X): "x",
            UInt32(kVK_ANSI_Y): "y", UInt32(kVK_ANSI_Z): "z",
            UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
            UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
            UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
            UInt32(kVK_ANSI_9): "9",
            UInt32(kVK_Space): " ",      UInt32(kVK_Delete): "\u{8}",
            UInt32(kVK_Return): "\r",    UInt32(kVK_Tab): "\t",
            UInt32(kVK_F1): "\u{F704}",  UInt32(kVK_F2): "\u{F705}",  UInt32(kVK_F3): "\u{F706}",
            UInt32(kVK_F4): "\u{F707}",  UInt32(kVK_F5): "\u{F708}",  UInt32(kVK_F6): "\u{F709}",
            UInt32(kVK_F7): "\u{F70A}",  UInt32(kVK_F8): "\u{F70B}",  UInt32(kVK_F9): "\u{F70C}",
            UInt32(kVK_F10): "\u{F70D}", UInt32(kVK_F11): "\u{F70E}", UInt32(kVK_F12): "\u{F70F}",
            UInt32(kVK_ANSI_Minus): "-",  UInt32(kVK_ANSI_Equal): "=",
            UInt32(kVK_ANSI_LeftBracket): "[",  UInt32(kVK_ANSI_RightBracket): "]",
            UInt32(kVK_ANSI_Semicolon): ";",    UInt32(kVK_ANSI_Quote): "'",
            UInt32(kVK_ANSI_Comma): ",",        UInt32(kVK_ANSI_Period): ".",
            UInt32(kVK_ANSI_Slash): "/",        UInt32(kVK_ANSI_Backslash): "\\",
            UInt32(kVK_ANSI_Grave): "`",
        ]
        return map[keyCode]
    }
}

enum ShortcutHelper {

    private static let defaults = UserDefaults.standard

    enum Key: String {
        case lock     = "com.sentry.shortcut.lock"
        case caffeine = "com.sentry.shortcut.caffeine"
    }

    static func save(_ shortcut: ShortcutConfig, forKey key: Key) {
        if let data = try? JSONEncoder().encode(shortcut) {
            defaults.set(data, forKey: key.rawValue)
        }
    }

    static func getDefault(forKey key: Key) -> ShortcutConfig {
        guard
            let data = defaults.data(forKey: key.rawValue),
            let shortcut = try? JSONDecoder().decode(ShortcutConfig.self, from: data)
        else {
            return defaultShortcut(for: key)
        }
        return shortcut
    }

    static func loadIfSet(forKey key: Key) -> ShortcutConfig? {
        guard
            let data = defaults.data(forKey: key.rawValue),
            let shortcut = try? JSONDecoder().decode(ShortcutConfig.self, from: data)
        else {
            return nil
        }
        return shortcut
    }

    static func reset(forKey key: Key) {
        defaults.removeObject(forKey: key.rawValue)
    }

    static func resetAll() {
        reset(forKey: .lock)
        reset(forKey: .caffeine)
    }

    static func defaultShortcut(for key: Key) -> ShortcutConfig {
        switch key {
        case .lock:
            return .defaultLock
        case .caffeine:
            return .defaultCaffeine
        }
    }
}
