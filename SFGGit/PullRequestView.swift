//
//  PullRequestView.swift
//  SFGGit
//
//  Created by Roman Volovelskyi on 18/11/2025.
//

import SwiftUI

struct PullRequestView: View {
    @State private var branchName = ""
    @State private var progressText = ""

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
                .frame(height: 200)
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
                .disabled(branchName.isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 500, minHeight: 400)
    }

    private func createPullRequest() {
        // TODO: Implement pull request creation logic
    }
}

#Preview {
    PullRequestView()
}