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
    
    @State private var installStatusText = "Install CLI Tool"
    @State private var cliInstallError = ""
    @State private var showSuccessAlert = false

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
        .padding(8)
        .padding(.horizontal, 4)
        .frame(
            minWidth: 650,
            minHeight: 420
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
