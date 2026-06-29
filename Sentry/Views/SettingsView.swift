//
//  SettingsView.swift
//  Sentry
//
//  Created by Monu Kumar on 12/03/26.
//

import SwiftUI
import Combine

struct SettingsView: View {

    @State private var lockShortcut: ShortcutConfig? = ShortcutHelper.loadIfSet(forKey: .lock)
    @State private var caffeineShortcut: ShortcutConfig? = ShortcutHelper.loadIfSet(forKey: .caffeine)
    
    @StateObject private var settings = SettingsManager.shared
    
    @State private var installStatusText = "Install CLI Tool"
    @State private var cliInstallError = ""
    @State private var showSuccessAlert = false

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    LabeledContent {
                        ShortcutRecorderView(shortcut: $lockShortcut)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lock Screen")
                            Text("Lock Mac & monitor running CLI tasks")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent {
                        ShortcutRecorderView(shortcut: $caffeineShortcut)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Caffeine Mode")
                            Text("Prevent Mac & display from sleeping")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
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
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Features:")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("• Lock Screen: Locks your Mac with Sentry's overlay to monitor command outputs, status logs, and view clock/date widgets.")
                            .font(.caption)
                        Text("• Caffeine Mode: Prevents your Mac from sleeping or turning off the display, keeping background processes active.")
                            .font(.caption)
                        
                        Text("Recording Shortcuts:")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.top, 4)
                        Text("• Click the field and press your key combination (e.g., ⌘⌥L or ⌃⌥C).\n• Shortcut must include at least one modifier key (⌘ Command, ⌥ Option, or ⌃ Control).\n• Press Escape to cancel recording. Click the 'x' button next to a shortcut to clear it.")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.leading, 4)
                
                Section {
                    Picker("Lock Screen Mode", selection: $settings.lockBehavior) {
                        ForEach(SettingsManager.LockBehavior.allCases) { behavior in
                            Text(behavior.displayName).tag(behavior)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Lock Screen Mode")
                        .font(.headline)
                }
                .padding(.leading, 4)
                
                if settings.lockBehavior == .custom {
                    Section {
                        Toggle("Show Clock & Date on Lock Screen", isOn: $settings.showClockWidget)
                    } header: {
                        Text("Clock Widget")
                            .font(.headline)
                    }
                    .padding(.leading, 4)
                }
                
                Section {
                    Toggle("Show Title Bar & Status Tag", isOn: $settings.cliShowTitleBar)
                    Stepper("Maximum Log Lines to Display: \(settings.cliLineLimit)", value: $settings.cliLineLimit, in: 3...10)
                } header: {
                    Text("Command Progress Card")
                        .font(.headline)
                }
                .padding(.leading, 4)
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Piping command output to the Sentry lock screen allows you to monitor running tasks without unlocking your Mac.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 4)
                        
                        HStack(spacing: 12) {
                            Button(action: installCliTool) {
                                HStack {
                                    Image(systemName: "terminal.fill")
                                    Text(installStatusText)
                                }
                            }
                            
                            Button("Copy Manual Install Command") {
                                copyManualCommand()
                            }
                        }
                        
                        if !cliInstallError.isEmpty {
                            Text(cliInstallError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 2)
                        } else if showSuccessAlert {
                            Text("Action completed successfully!")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.top, 2)
                        }
                    }
                } header: {
                    Text("CLI Integration")
                        .font(.headline)
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Usage:")
                            .font(.caption)
                            .fontWeight(.bold)
                        Text("• Pipe output:  `make build | sentry-cli --title \"Build\"` \n• Subcommand: `sentry-cli --title \"Test\" -- sleep 5` \n• Use `-c` / `--clear` option to automatically remove progress on completion.")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.leading, 4)
            }
            .formStyle(.grouped)
            .padding(.horizontal, 4)
        }
        .frame(
            minWidth: 650,
            minHeight: 450
        )
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
    
    private func checkCliStatus() {
        let fm = FileManager.default
        let targetPath = "/usr/local/bin/sentry-cli"
        if fm.fileExists(atPath: targetPath) {
            if let dest = try? fm.destinationOfSymbolicLink(atPath: targetPath) {
                if let cliURL = Bundle.main.url(forResource: "sentry-cli", withExtension: nil), dest == cliURL.path {
                    installStatusText = "CLI Installed (Up to Date)"
                    return
                }
            }
            installStatusText = "Update CLI Tool"
        } else {
            installStatusText = "Install CLI Tool"
        }
    }
    
    private func installCliTool() {
        cliInstallError = ""
        showSuccessAlert = false
        
        guard let cliURL = Bundle.main.url(forResource: "sentry-cli", withExtension: nil) else {
            cliInstallError = "Error: Bundled sentry-cli not found in App resources. Make sure the app is built."
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

#Preview {
    SettingsView()
}
