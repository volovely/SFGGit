//
//  SettingsView.swift
//  SFGGit
//
//  Created by Roman Volovelskyi on 18/11/2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var repositoryPath = ""
    @State private var sshKeyPath = ""
    @State private var claudeAPIKey = ""
    @State private var isEnabled = true

    @State private var originalRepositoryPath = ""
    @State private var originalSshKeyPath = ""
    @State private var originalClaudeAPIKey = ""
    @State private var originalIsEnabled = true

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)

            GroupBox("Repository Configuration") {
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Repository Path:")
                            .fontWeight(.medium)
                        HStack {
                            TextField("Select repository folder", text: $repositoryPath)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Browse...") {
                                selectRepositoryFolder()
                            }
                            .buttonStyle(BorderedButtonStyle())
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("SSH Key Path:")
                            .fontWeight(.medium)
                        HStack {
                            TextField("Select SSH key file", text: $sshKeyPath)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Browse...") {
                                selectSSHKeyFile()
                            }
                            .buttonStyle(BorderedButtonStyle())
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Claude API Key:")
                            .fontWeight(.medium)
                        SecureField("Enter your Claude API key", text: $claudeAPIKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("Your API key is stored securely in Keychain")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
            }

            GroupBox("General") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Enable SFGGit", isOn: $isEnabled)
                }
                .padding(10)
            }

            GroupBox("About") {
                VStack(alignment: .leading, spacing: 5) {
                    Text("SFGGit")
                        .font(.headline)
                    Text("Version 1.0")
                        .foregroundColor(.secondary)
                    Text("A Git menu bar application with Claude integration")
                        .foregroundColor(.secondary)
                }
                .padding(10)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") {
                    cancelChanges()
                }
                .buttonStyle(BorderedButtonStyle())

                Button("Save") {
                    saveSettings()
                }
                .buttonStyle(BorderedProminentButtonStyle())
            }
            .padding(.top, 10)
        }
        .padding(20)
        .onAppear {
            loadSettings()
        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//        .frame(minWidth: 500, minHeight: 400)
    }

    private func loadSettings() {
        repositoryPath = UserDefaults.standard.string(forKey: "repositoryPath") ?? ""
        sshKeyPath = UserDefaults.standard.string(forKey: "sshKeyPath") ?? ""
        claudeAPIKey = UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
        isEnabled = UserDefaults.standard.bool(forKey: "isEnabled")

        originalRepositoryPath = repositoryPath
        originalSshKeyPath = sshKeyPath
        originalClaudeAPIKey = claudeAPIKey
        originalIsEnabled = isEnabled
    }

    private func saveSettings() {
        UserDefaults.standard.set(repositoryPath, forKey: "repositoryPath")
        UserDefaults.standard.set(sshKeyPath, forKey: "sshKeyPath")
        UserDefaults.standard.set(claudeAPIKey, forKey: "claudeAPIKey")
        UserDefaults.standard.set(isEnabled, forKey: "isEnabled")

        originalRepositoryPath = repositoryPath
        originalSshKeyPath = sshKeyPath
        originalClaudeAPIKey = claudeAPIKey
        originalIsEnabled = isEnabled

        dismiss()
    }

    private func cancelChanges() {
        repositoryPath = originalRepositoryPath
        sshKeyPath = originalSshKeyPath
        claudeAPIKey = originalClaudeAPIKey
        isEnabled = originalIsEnabled

        dismiss()
    }

    private func selectRepositoryFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Repository Folder"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false

        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                repositoryPath = url.path
            }
        }
    }

    private func selectSSHKeyFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select SSH Key File"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true

        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                sshKeyPath = url.path
            }
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 500, height: 400)
}
