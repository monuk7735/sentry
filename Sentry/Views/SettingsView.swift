//
//  SettingsView.swift
//  Sentry
//
//  Created by Monu Kumar on 12/03/26.
//

import SwiftUI
import Combine

enum SettingsTab: String, CaseIterable, Identifiable {
    case shortcuts = "Shortcuts"
    case lockScreen = "Lock Screen"
    case cli = "CLI Tool"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .shortcuts: return "keyboard.fill"
        case .lockScreen: return "lock.fill"
        case .cli: return "terminal.fill"
        }
    }
}

struct SettingsView: View {
    @State private var lockShortcut: ShortcutConfig? = ShortcutHelper.loadIfSet(forKey: .lock)
    @State private var caffeineShortcut: ShortcutConfig? = ShortcutHelper.loadIfSet(forKey: .caffeine)
    
    @StateObject private var settings = SettingsManager.shared
    
    @State private var installStatusText = "Install CLI Tool"
    @State private var isCliInstalled = false
    @State private var cliInstallError = ""
    @State private var showSuccessAlert = false
    @State private var isHoveringDone = false
    @State private var isHoveringInstall = false
    
    var body: some View {
        ZStack {
            // Background subtle gradient fill
            LinearGradient(
                colors: [Color.blue.opacity(0.04), Color.indigo.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 12) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.85), Color.indigo],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                .frame(width: 52, height: 52)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Sentry Settings")
                                .font(.system(size: 24, weight: .bold))
                            
                            Text("Configure keyboard shortcuts, lock screen behavior, and CLI integration")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 24)
                    
                    // Cute Segmented Tab Selector
                    HStack(spacing: 6) {
                        ForEach(SettingsTab.allCases) { tab in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    settings.selectedTab = tab
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.iconName)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(tab.rawValue)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(settings.selectedTab == tab ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(settings.selectedTab == tab ? Color.blue : Color.primary.opacity(0.06))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 6)
                }
                
                Divider()
                    .padding(.horizontal, 36)
                    .padding(.top, 14)
                
                // Tab Content Area
                ZStack {
                    switch settings.selectedTab {
                    case .shortcuts:
                        shortcutsTab
                    case .lockScreen:
                        lockScreenTab
                    case .cli:
                        cliTab
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                
                // Bottom Done Action Button
                VStack(spacing: 0) {
                    Button(action: {
                        SettingsWindowManager.shared.close()
                    }) {
                        Text("Done")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                isHoveringDone ? Color.blue.opacity(0.9) : Color.blue,
                                                isHoveringDone ? Color.indigo.opacity(0.9) : Color.indigo
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                            )
                            .scaleEffect(isHoveringDone ? 1.01 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: isHoveringDone)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                    .onHover { hovering in
                        isHoveringDone = hovering
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 24)
            }
        }
        .frame(width: 680, height: 540)
        .onAppear {
            checkCliStatus()
        }
        .onChange(of: lockShortcut) { newValue in
            if let shortcut = newValue {
                ShortcutHelper.save(shortcut, forKey: .lock)
            } else {
                ShortcutHelper.reset(forKey: .lock)
            }
            HotKeyManager.shared.reloadShortcuts()
            SettingsManager.shared.objectWillChange.send()
        }
        .onChange(of: caffeineShortcut) { newValue in
            if let shortcut = newValue {
                ShortcutHelper.save(shortcut, forKey: .caffeine)
            } else {
                ShortcutHelper.reset(forKey: .caffeine)
            }
            HotKeyManager.shared.reloadShortcuts()
            SettingsManager.shared.objectWillChange.send()
        }
    }
    
    // MARK: - Tab 1: Shortcuts Tab
    private var shortcutsTab: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                // Lock Screen Shortcut Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.blue.opacity(0.14))
                                .frame(width: 36, height: 36)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lock Screen Shortcut")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Lock Mac & monitor CLI tasks")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ShortcutRecorderView(shortcut: $lockShortcut)
                        .padding(.top, 4)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.025))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                )
                
                // Keep Awake Shortcut Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.orange.opacity(0.14))
                                .frame(width: 36, height: 36)
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Keep Awake Shortcut")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Prevent Mac & display sleep")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ShortcutRecorderView(shortcut: $caffeineShortcut)
                        .padding(.top, 4)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.025))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                )
            }
            
            // Instruction Banner
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text("Click a shortcut field and press your key combination (e.g. ⌘⌥L or ⌃⌥C). Must include at least one modifier key (⌘, ⌥, or ⌃).")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
                
                Spacer()
                
                Button("Reset Defaults") {
                    ShortcutHelper.resetAll()
                    lockShortcut = ShortcutHelper.getDefault(forKey: .lock)
                    caffeineShortcut = ShortcutHelper.getDefault(forKey: .caffeine)
                }
                .font(.system(size: 12, weight: .medium))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.06))
            )
            
            Spacer()
        }
    }
    
    // MARK: - Tab 2: Lock Screen Tab
    private var lockScreenTab: some View {
        VStack(spacing: 16) {
            // Lock Screen Mode Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Lock Screen Mode")
                    .font(.system(size: 14, weight: .semibold))
                
                Picker("", selection: $settings.lockBehavior) {
                    ForEach(SettingsManager.LockBehavior.allCases) { behavior in
                        Text(behavior.displayName).tag(behavior)
                    }
                }
                .pickerStyle(.segmented)
                
                Text(
                    settings.lockBehavior == .custom
                    ? "Custom Overlay displays Sentry's Touch ID screen with clock widget and live command progress."
                    : "System Lock triggers macOS native lock screen."
                )
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.025))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
            )
            
            if settings.lockBehavior == .custom {
                // Clock Widget Toggle Card
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Show Clock & Date Widget")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Displays current date and large digital clock on Sentry lock screen")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $settings.showClockWidget)
                        .toggleStyle(.switch)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.025))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Tab 3: CLI Integration Tab
    private var cliTab: some View {
        VStack(spacing: 12) {
            // Options & Installation Card
            VStack(alignment: .leading, spacing: 12) {
                // Header with Checkbox / Status Indicator Badge
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: isCliInstalled ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(isCliInstalled ? .green : .orange)
                        
                        Text(isCliInstalled ? "sentry-cli Installed & Ready" : "sentry-cli Not Installed")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isCliInstalled ? .green : .orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(isCliInstalled ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                    )
                    
                    Spacer()
                    
                    Button(action: installCliTool) {
                        HStack(spacing: 6) {
                            Image(systemName: isCliInstalled ? "arrow.triangle.2.circlepath" : "arrow.down.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text(installStatusText)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(isHoveringInstall ? Color.blue.opacity(0.9) : Color.blue)
                        )
                        .scaleEffect(isHoveringInstall ? 1.03 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: isHoveringInstall)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isHoveringInstall = hovering
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                
                Divider()
                
                // Display Toggles & Stepper
                HStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Title Bar & Status Tag")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Displays command title and running/success status tag")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.cliShowTitleBar)
                            .toggleStyle(.switch)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Max Log Lines")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Lines to render on lock screen")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Stepper("\(settings.cliLineLimit) lines", value: $settings.cliLineLimit, in: 3...10)
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.025))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
            )
            
            // Example Command Snippets Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Example Terminal Commands")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Button("Copy Install Command") {
                        copyManualCommand()
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                
                VStack(spacing: 8) {
                    CodeSnippetRow(
                        label: "Pipe command output:",
                        command: "make build | sentry-cli --title \"Build\""
                    )
                    
                    CodeSnippetRow(
                        label: "Run subcommand:",
                        command: "sentry-cli --title \"Test Run\" -- sleep 5"
                    )
                    
                    CodeSnippetRow(
                        label: "Auto-clear on finish:",
                        command: "sentry-cli --clear --title \"Task\" -- ./script.sh"
                    )
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.025))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
            )
            
            if !cliInstallError.isEmpty {
                Text(cliInstallError)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            } else if showSuccessAlert {
                Text("Action completed successfully!")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
    }
    
    // MARK: - CLI Tool Helpers
    
    private func checkCliStatus() {
        let fm = FileManager.default
        let targetPath = "/usr/local/bin/sentry-cli"
        if fm.fileExists(atPath: targetPath) {
            if let dest = try? fm.destinationOfSymbolicLink(atPath: targetPath) {
                if let cliURL = Bundle.main.url(forResource: "sentry-cli", withExtension: nil), dest == cliURL.path {
                    installStatusText = "CLI Installed (Up to Date)"
                    isCliInstalled = true
                    return
                }
            }
            installStatusText = "Update CLI Tool"
            isCliInstalled = false
        } else {
            installStatusText = "Install CLI Tool"
            isCliInstalled = false
        }
    }
    
    private func installCliTool() {
        cliInstallError = ""
        showSuccessAlert = false
        
        guard let cliURL = Bundle.main.url(forResource: "sentry-cli", withExtension: nil) else {
            cliInstallError = "Error: Bundled sentry-cli not found in App resources."
            return
        }
        
        let fm = FileManager.default
        let binDir = "/usr/local/bin"
        let targetPath = "\(binDir)/sentry-cli"
        
        var needsAdmin = false
        if !fm.fileExists(atPath: binDir) {
            needsAdmin = true
        } else if !fm.isWritableFile(atPath: binDir) {
            needsAdmin = true
        } else if fm.fileExists(atPath: targetPath) && !fm.isWritableFile(atPath: targetPath) {
            needsAdmin = true
        }
        
        if needsAdmin {
            let scriptSource = "do shell script \"mkdir -p /usr/local/bin && ln -sf '\(cliURL.path)' /usr/local/bin/sentry-cli\" with administrator privileges"
            guard let appleScript = NSAppleScript(source: scriptSource) else {
                cliInstallError = "Failed to initialize installation script."
                return
            }
            
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let err = error {
                let errorMsg = err[NSAppleScript.errorMessage] as? String ?? "Authorization failed"
                cliInstallError = "Installation failed: \(errorMsg)"
            } else {
                showSuccessAlert = true
                checkCliStatus()
            }
        } else {
            do {
                if fm.fileExists(atPath: targetPath) {
                    try fm.removeItem(atPath: targetPath)
                }
                try fm.createSymbolicLink(atPath: targetPath, withDestinationPath: cliURL.path)
                showSuccessAlert = true
                checkCliStatus()
            } catch {
                cliInstallError = "Installation failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func copyManualCommand() {
        cliInstallError = ""
        guard let cliURL = Bundle.main.url(forResource: "sentry-cli", withExtension: nil) else {
            cliInstallError = "Error: Bundled sentry-cli not found in App resources."
            return
        }
        
        let cmd = "mkdir -p /usr/local/bin && ln -sf \"\(cliURL.path)\" /usr/local/bin/sentry-cli"
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(cmd, forType: .string)
        
        showSuccessAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showSuccessAlert = false
        }
    }
}

// MARK: - Code Snippet Row Helper

private struct CodeSnippetRow: View {
    let label: String
    let command: String
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack {
                Text(command)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.green)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                    isCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isCopied = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10))
                        Text(isCopied ? "Copied" : "Copy")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.white.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.82))
            )
        }
    }
}
