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

    @State private var isRecording = false
    @State private var isHovered   = false
    @State private var eventMonitor: Any?

    var body: some View {
        HStack(spacing: 6) {

            Button(action: toggleRecording) {
                Text(pillLabel)
                    .font(.body)
                    .foregroundStyle(isRecording || isHovered ? Color.accentColor : Color.primary)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(NSColor.controlColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .animation(.easeInOut(duration: 0.15), value: isHovered)
                    .animation(.easeInOut(duration: 0.15), value: isRecording)
            }
            .buttonStyle(.plain)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.bar)
            }
            .onHover { isHovered = $0 }

            if shortcut != nil {
                Button {
                    shortcut = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .help("Clear shortcut")
            }
        }
        .onChange(of: isRecording) { recording in
            if recording { startMonitoring() } else { stopMonitoring() }
        }
        .onDisappear {
            stopMonitoring()
        }
    }

    private var pillLabel: String {
        if isRecording || isHovered { return "Record Shortcut" }
        return shortcut?.displayString ?? "Record Shortcut"
    }

    private func toggleRecording() {
        isRecording.toggle()
    }

    private func startMonitoring() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown, .rightMouseDown]
        ) { event in
            if event.type == .leftMouseDown || event.type == .rightMouseDown {
                isRecording = false
                return event
            }

            if event.keyCode == UInt16(kVK_Escape) {
                isRecording = false
                return nil
            }

            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
            guard mods.contains(.command) || mods.contains(.control) || mods.contains(.option) else {
                NSSound.beep()
                return nil
            }

            shortcut = ShortcutConfig(
                keyCode: UInt32(event.keyCode),
                modifiers: carbonModifiers(from: mods)
            )
            isRecording = false
            isHovered   = false
            return nil
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
