//
//  ShortcutRecorderView.swift
//  Sentry
//
//  Created by Monu Kumar on 12/03/26.
//

import SwiftUI
import Carbon

struct ShortcutRecorderView: View {
    @Binding var shortcut: ShortcutConfig?
    var title: String = "Keyboard Shortcut"

    @State private var isShowingModal = false
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                isShowingModal = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 13, weight: .semibold))
                    
                    Text(shortcut?.displayString ?? "Record Shortcut")
                        .font(.system(size: 13, weight: .semibold, design: shortcut != nil ? .monospaced : .default))
                        .kerning(shortcut != nil ? 4 : 0)
                }
                .foregroundColor(shortcut != nil ? .blue : (isHovered ? .blue : .primary))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(shortcut != nil ? Color.blue.opacity(0.1) : Color.primary.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(shortcut != nil ? Color.blue.opacity(0.4) : (isHovered ? Color.blue.opacity(0.3) : Color.clear), lineWidth: 1)
                        )
                )
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }

            if shortcut != nil {
                Button(action: {
                    shortcut = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Clear shortcut")
            }
        }
        .sheet(isPresented: $isShowingModal) {
            ShortcutRecorderModalView(
                title: title,
                shortcut: $shortcut,
                isPresented: $isShowingModal
            )
        }
    }
}

// MARK: - Dedicated Recording Modal View

struct ShortcutRecorderModalView: View {
    let title: String
    @Binding var shortcut: ShortcutConfig?
    @Binding var isPresented: Bool
    
    @State private var currentFlags: NSEvent.ModifierFlags = []
    @State private var pressedKeyString: String = ""
    @State private var warningMessage: String = ""
    @State private var isSuccess: Bool = false
    @State private var eventMonitor: Any?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Record \(title)")
                        .font(.system(size: 17, weight: .bold))
                    Text("Press your desired key combination on your keyboard")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Interactive Live Key Display Box
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    KeyBadge(label: "⌘ Command", isActive: currentFlags.contains(.command))
                    KeyBadge(label: "⌥ Option", isActive: currentFlags.contains(.option))
                    KeyBadge(label: "⌃ Control", isActive: currentFlags.contains(.control))
                    KeyBadge(label: "⇧ Shift", isActive: currentFlags.contains(.shift))
                }
                
                // Key Output Box
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSuccess ? Color.green.opacity(0.12) : Color.primary.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSuccess ? Color.green : Color.blue.opacity(0.4), lineWidth: 1.5)
                        )
                        .frame(height: 60)
                    
                    if isSuccess {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                            Text("Saved \(shortcut?.displayString ?? "")")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                        }
                    } else if !pressedKeyString.isEmpty {
                        Text(pressedKeyString)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                    } else {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Waiting for key combination...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if !warningMessage.isEmpty {
                Text(warningMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)
            } else {
                Text("Shortcut must include at least one modifier key (⌘, ⌥, or ⌃)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            // Footer Action Buttons
            HStack {
                if shortcut != nil {
                    Button(action: {
                        shortcut = nil
                        isPresented = false
                    }) {
                        Text("Clear Shortcut")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 440, height: 290)
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
    }
    
    private func startMonitoring() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .flagsChanged]
        ) { event in
            if event.type == .flagsChanged {
                let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
                currentFlags = mods
                return nil
            }
            
            if event.type == .keyDown {
                if event.keyCode == UInt16(kVK_Escape) {
                    isPresented = false
                    return nil
                }
                
                let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
                guard mods.contains(.command) || mods.contains(.control) || mods.contains(.option) else {
                    NSSound.beep()
                    warningMessage = "Please hold ⌘ Command, ⌥ Option, or ⌃ Control while pressing a key."
                    return nil
                }
                
                warningMessage = ""
                let newShortcut = ShortcutConfig(
                    keyCode: UInt32(event.keyCode),
                    modifiers: carbonModifiers(from: mods)
                )
                shortcut = newShortcut
                pressedKeyString = newShortcut.displayString
                isSuccess = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isPresented = false
                }
                return nil
            }
            
            return event
        }
    }

    private func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.command) { mods |= UInt32(cmdKey)     }
        if flags.contains(.shift)   { mods |= UInt32(shiftKey)   }
        if flags.contains(.option)  { mods |= UInt32(optionKey)  }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        return mods
    }
}

private struct KeyBadge: View {
    let label: String
    let isActive: Bool
    
    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(isActive ? .white : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isActive ? Color.blue : Color.primary.opacity(0.06))
            )
            .animation(.easeInOut(duration: 0.1), value: isActive)
    }
}
