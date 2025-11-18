//
//  PushView.swift
//  SFGGit
//
//  Created by Roman Volovelskyi on 18/11/2025.
//

import SwiftUI

struct PushView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gitClient = GitClient()
    @StateObject private var claudeClient = ClaudeClient()
    @State private var diffContent = ""
    @State private var commitMessage = ""
    @State private var pushStatus = ""
    @State private var isLoading = false
    @State private var isGeneratingMessage = false
    @State private var isPushing = false
    @State private var isCommitting = false
    @State private var prData: PRData?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Push Configuration")
                .font(.title2)
                .fontWeight(.bold)

            GroupBox("Git Diff (Staged Changes)") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button("Refresh Diff") {
                            loadDiff()
                        }
                        .buttonStyle(BorderedButtonStyle())

                        Button("Generate Commit Message") {
                            generateCommitMessage()
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .disabled(diffContent.isEmpty || isGeneratingMessage)

                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }

                        if isGeneratingMessage {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Generating...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }

                    ScrollView {
                        if diffContent.isEmpty {
                            Text("No changes to commit. All files are up to date.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        } else {
                            Text(diffContent)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }
                    .frame(minHeight: 150)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(10)
            }

            GroupBox("Commit Message") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button("Commit") {
                            commitChanges()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .disabled(commitMessage.isEmpty || isCommitting || isPushing || prData == nil)

                        Button("Push Changes") {
                            pushChanges()
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .disabled(commitMessage.isEmpty || isPushing || isCommitting || prData == nil)

                        if isCommitting {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Committing...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if isPushing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Pushing...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }

                    ScrollView {
                        if commitMessage.isEmpty {
                            Text("No commit message generated yet. Click 'Generate Commit Message' above.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        } else {
                            Text(commitMessage)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }
                    .frame(minHeight: 80)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(10)
            }

            GroupBox("Push Status") {
                VStack(alignment: .leading, spacing: 10) {
                    ScrollView {
                        if pushStatus.isEmpty {
                            Text("No push operations yet. Generate a commit message and click 'Push Changes'.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        } else {
                            Text(pushStatus)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }
                    .frame(minHeight: 60)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(10)
            }

            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(BorderedProminentButtonStyle())
            }
            .padding(.top, 10)
        }
        .padding(20)
        .frame(minWidth: 600, minHeight: 650)
        .onAppear {
            loadDiff()
        }
    }

    private func loadDiff() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            // First stage all changes
            let stageSuccess = self.gitClient.stageAllChanges()

            if stageSuccess {
                // Then get staged diff
                let diff = self.gitClient.getStagedDiff()
                DispatchQueue.main.async {
                    self.diffContent = diff ?? ""
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.diffContent = "Failed to stage changes. Please check git status."
                    self.isLoading = false
                }
            }
        }
    }

    private func generateCommitMessage() {
        guard !diffContent.isEmpty else { return }

        isGeneratingMessage = true
        Task {
            if let response = await claudeClient.generatePRData(from: diffContent) {
                await MainActor.run {
                    self.prData = response
                    self.commitMessage = "Title: \(response.title)\n\nMessage: \(response.message)"
                    self.isGeneratingMessage = false
                }
            } else {
                await MainActor.run {
                    self.prData = nil
                    self.commitMessage = "Failed to generate the message."
                    self.isGeneratingMessage = false
                }
            }
        }
    }

    private func commitChanges() {
        guard let prData = prData else {
            pushStatus = "Error: No commit message data available"
            return
        }

        isCommitting = true
        pushStatus = "Starting commit process..."

        Task {
            await MainActor.run {
                self.pushStatus = "Staging all changes..."
            }

            let stageSuccess = gitClient.stageAllChanges()

            if !stageSuccess {
                await MainActor.run {
                    self.pushStatus = "Failed to stage changes. Check git status."
                    self.isCommitting = false
                }
                return
            }

            await MainActor.run {
                self.pushStatus = "Changes staged successfully. Committing..."
            }

            let commitSuccess = gitClient.commit(title: prData.title, message: prData.message)

            await MainActor.run {
                if commitSuccess {
                    self.pushStatus = "✅ Successfully committed changes locally!\n\nTitle: \(prData.title)"
                } else {
                    self.pushStatus = "❌ Failed to commit changes. Check git configuration."
                }
                self.isCommitting = false
            }
        }
    }

    private func pushChanges() {
        guard let prData = prData else {
            pushStatus = "Error: No commit message data available"
            return
        }

        isPushing = true
        pushStatus = "Starting push process..."

        Task {
            await MainActor.run {
                self.pushStatus = "Staging all changes..."
            }

            let stageSuccess = gitClient.stageAllChanges()

            if !stageSuccess {
                await MainActor.run {
                    self.pushStatus = "Failed to stage changes. Check git status."
                    self.isPushing = false
                }
                return
            }

            await MainActor.run {
                self.pushStatus = "Changes staged successfully. Committing and pushing..."
            }

            let pushSuccess = gitClient.commitAndPush(title: prData.title, message: prData.message)

            await MainActor.run {
                if pushSuccess {
                    self.pushStatus = "✅ Successfully pushed changes to remote repository!\n\nTitle: \(prData.title)"
                } else {
                    self.pushStatus = "❌ Failed to commit and push changes. Check git configuration and remote access."
                }
                self.isPushing = false
            }
        }
    }
}

#Preview {
    PushView()
        .frame(width: 400, height: 300)
}
