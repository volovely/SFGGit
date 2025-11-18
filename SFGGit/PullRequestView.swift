//
//  PullRequestView.swift
//  SFGGit
//
//  Created by Roman Volovelskyi on 18/11/2025.
//

import SwiftUI

struct PullRequestView: View {
    @State private var branchName = "main"
    @State private var prTitle = ""
    @State private var prDescription = ""
    @State private var progressText = ""
    @State private var isGenerating = false

    @StateObject private var gitClient = GitClient()
    @StateObject private var claudeClient = ClaudeClient()

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Create Pull Request")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 10) {
                Text("Branch Name:")
                    .fontWeight(.medium)
                TextField("Enter branch name", text: $branchName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("PR Title & Description:")
                        .fontWeight(.medium)
                    Spacer()
                    Button("Generate from Diff") {
                        generatePRInfo()
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .disabled(branchName.isEmpty || isGenerating)

                    if isGenerating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Generating...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Title:")
                        .font(.caption)
                        .fontWeight(.medium)
                    TextField("PR title will be generated", text: $prTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Description:")
                        .font(.caption)
                        .fontWeight(.medium)
                    ScrollView {
                        TextEditor(text: $prDescription)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    .frame(height: 120)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Progress:")
                    .fontWeight(.medium)

                ScrollView {
                    Text(progressText.isEmpty ? "Ready to create pull request..." : progressText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(progressText.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }
                .frame(height: 100)
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(BorderedButtonStyle())

                Button("Create") {
                    createPullRequest()
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .disabled(branchName.isEmpty || prTitle.isEmpty || prDescription.isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 600, minHeight: 650)
    }

    private func generatePRInfo() {
        guard !branchName.isEmpty else {
            progressText = "Please enter a branch name first"
            return
        }

        isGenerating = true
        progressText = "Getting diff against main branch..."

        Task {
            // Get diff against main branch
            let diffResult = gitClient.getDiffAgainstBranch(targetBranch: "main")

            if !diffResult.success {
                await MainActor.run {
                    self.progressText = "❌ Failed to get diff: \(diffResult.diff)"
                    self.isGenerating = false
                }
                return
            }

            if diffResult.diff.isEmpty {
                await MainActor.run {
                    self.progressText = "No differences found compared to main branch"
                    self.isGenerating = false
                }
                return
            }

            await MainActor.run {
                self.progressText = "Generating PR title and description..."
            }

            // Generate PR info using Claude
            if let prInfo = await claudeClient.generatePRInfo(from: diffResult.diff) {
                await MainActor.run {
                    self.prTitle = prInfo.title
                    self.prDescription = prInfo.summary
                    self.progressText = "✅ PR title and description generated successfully!"
                    self.isGenerating = false
                }
            } else {
                await MainActor.run {
                    self.progressText = "❌ Failed to generate PR info. Check Claude API key configuration."
                    self.isGenerating = false
                }
            }
        }
    }

    private func createPullRequest() {
        guard !branchName.isEmpty, !prTitle.isEmpty, !prDescription.isEmpty else {
            progressText = "Please fill in all fields"
            return
        }

        progressText = "Creating pull request..."

        Task {
            let result = gitClient.createPullRequest(
                branchName: branchName,
                title: prTitle,
                body: prDescription
            )

            await MainActor.run {
                if result.success {
                    self.progressText = "✅ Pull request created successfully!\n\n\(result.output)"
                } else {
                    self.progressText = "❌ Failed to create pull request:\n\n\(result.output)"
                }
            }
        }
    }
}

#Preview {
    PullRequestView()
}
