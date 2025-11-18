//
//  GitClient.swift
//  SFGGit
//
//  Created by Roman Volovelskyi on 18/11/2025.
//

import Foundation

class GitClient: ObservableObject {

    private var repositoryPath: String {
        return UserDefaults.standard.string(forKey: "repositoryPath") ?? ""
    }
    
    private var sshKeyPath: String {
        return UserDefaults.standard.string(forKey: "sshKeyPath") ?? ""
    }

    func getDiff() -> String? {
        guard !repositoryPath.isEmpty else {
            print("Repository path not configured")
            return nil
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["diff"]
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            if process.terminationStatus != 0 {
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("Git diff failed with error: \(errorString)")
                return nil
            }

            return String(data: outputData, encoding: .utf8)
        } catch {
            print("Failed to execute git diff: \(error)")
            return nil
        }
    }

    func getStagedDiff() -> String? {
        guard !repositoryPath.isEmpty else {
            print("Repository path not configured")
            return nil
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["diff", "--staged"]
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            if process.terminationStatus != 0 {
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("Git diff --staged failed with error: \(errorString)")
                return nil
            }

            return String(data: outputData, encoding: .utf8)
        } catch {
            print("Failed to execute git diff --staged: \(error)")
            return nil
        }
    }

    func stageAllChanges() -> Bool {
        guard !repositoryPath.isEmpty else {
            print("Repository path not configured")
            return false
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["add", "."]
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("Git add failed with error: \(errorString)")
                return false
            }

            print("Successfully staged all changes")
            return true
        } catch {
            print("Failed to execute git add: \(error)")
            return false
        }
    }

    func commit(title: String, message: String) -> Bool {
        guard !repositoryPath.isEmpty else {
            print("Repository path not configured")
            return false
        }

        // Commit the changes
        let commitProcess = Process()
        commitProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        commitProcess.arguments = ["commit", "-m", title, "-m", message]
        commitProcess.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        let commitErrorPipe = Pipe()
        commitProcess.standardError = commitErrorPipe

        do {
            try commitProcess.run()
            commitProcess.waitUntilExit()

            if commitProcess.terminationStatus != 0 {
                let errorData = commitErrorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("Git commit failed with error: \(errorString)")
                return false
            }

            print("Successfully committed changes")
            return true
        } catch {
            print("Failed to execute git commit: \(error)")
            return false
        }
    }

    func commitAndPush(title: String, message: String) -> Bool {
        // First commit the changes
        guard commit(title: title, message: message) else {
            return false
        }

        // Then push to remote
        return gitPushWithSSHKey()
    }
    
    func gitPushWithSSHKey() -> Bool {
        guard !sshKeyPath.isEmpty else {
            print("SSH key path not configured")
            return false
        }

        guard !repositoryPath.isEmpty else {
            print("Repository path not configured")
            return false
        }

        // Get current branch name
        guard let currentBranch = getCurrentBranch() else {
            print("Failed to get current branch name")
            return false
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")

        // Environment with custom SSH command
        var env = ProcessInfo.processInfo.environment
        env["GIT_SSH_COMMAND"] = #"ssh -i "# + sshKeyPath + #" -o IdentitiesOnly=yes"#
        process.environment = env
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        // Arguments: git push -u origin currentBranch (set upstream and push)
        process.arguments = ["git", "push", "-u", "origin", currentBranch]

        // Capture output
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                print("Successfully pushed branch '\(currentBranch)' to origin")
                print(output)
                return true
            } else {
                print("Failed to push branch '\(currentBranch)': \(output)")
                return false
            }
        } catch {
            print("Failed to run process:", error)
            return false
        }
    }

    private func getCurrentBranch() -> String? {
        guard !repositoryPath.isEmpty else {
            return nil
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["branch", "--show-current"]
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let branchName = String(data: outputData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return branchName?.isEmpty == false ? branchName : nil
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let error = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                print("Failed to get current branch: \(error)")
                return nil
            }
        } catch {
            print("Failed to execute git branch command: \(error)")
            return nil
        }
    }

    func getDiffAgainstBranch(targetBranch: String) -> (success: Bool, diff: String) {
        guard !repositoryPath.isEmpty else {
            return (false, "Repository path not configured")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["diff", targetBranch + "...HEAD"]
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                return (true, output)
            } else {
                return (false, error.isEmpty ? "Unknown error getting diff" : error)
            }
        } catch {
            return (false, "Failed to execute git diff: \(error.localizedDescription)")
        }
    }

    func getDiffAgainstBranchWithGH(targetBranch: String, currentBranch: String? = nil) -> (success: Bool, diff: String) {
        guard !repositoryPath.isEmpty else {
            return (false, "Repository path not configured")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/gh")

        var arguments = ["pr", "diff"]

        if let current = currentBranch {
            arguments.append("--name-only")
            arguments.append(current)
        }

        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                return (true, output)
            } else {
                // If gh pr diff fails, fallback to git diff
                return getDiffAgainstBranch(targetBranch: targetBranch)
            }
        } catch {
            // If gh CLI fails, fallback to git diff
            return getDiffAgainstBranch(targetBranch: targetBranch)
        }
    }

    func createPullRequest(branchName: String, title: String, body: String) -> (success: Bool, output: String) {
        guard !repositoryPath.isEmpty else {
            return (false, "Repository path not configured")
        }

        // First, check if branch exists and switch to it
        let checkoutResult = checkoutBranch(branchName: branchName)
        if !checkoutResult.success {
            return (false, "Failed to checkout branch '\(branchName)': \(checkoutResult.output)")
        }

        // Push the branch to remote if not already pushed
        let pushResult = pushBranch(branchName: branchName)
        if !pushResult.success {
            return (false, "Failed to push branch '\(branchName)': \(pushResult.output)")
        }

        // Create PR using gh CLI
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/gh")
        process.arguments = [
            "pr", "create",
            "--title", title,
            "--body", body,
            "--head", branchName
        ]
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                return (true, output.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                return (false, error.isEmpty ? "Unknown error creating PR" : error)
            }
        } catch {
            return (false, "Failed to execute gh CLI: \(error.localizedDescription)")
        }
    }

    private func checkoutBranch(branchName: String) -> (success: Bool, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["checkout", "-b", branchName]
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""

            // Branch might already exist, try to switch to it
            if process.terminationStatus != 0 {
                let switchProcess = Process()
                switchProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
                switchProcess.arguments = ["checkout", branchName]
                switchProcess.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

                let switchOutputPipe = Pipe()
                let switchErrorPipe = Pipe()

                switchProcess.standardOutput = switchOutputPipe
                switchProcess.standardError = switchErrorPipe

                try switchProcess.run()
                switchProcess.waitUntilExit()

                let switchOutput = String(data: switchOutputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let switchError = String(data: switchErrorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

                if switchProcess.terminationStatus == 0 {
                    return (true, switchOutput)
                } else {
                    return (false, switchError.isEmpty ? error : switchError)
                }
            }

            return (true, output)
        } catch {
            return (false, "Failed to checkout branch: \(error.localizedDescription)")
        }
    }

    private func pushBranch(branchName: String) -> (success: Bool, output: String) {
        guard !sshKeyPath.isEmpty else {
            return (false, "SSH key path not configured")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")

        // Environment with custom SSH command
        var env = ProcessInfo.processInfo.environment
        env["GIT_SSH_COMMAND"] = #"ssh -i "# + sshKeyPath + #" -o IdentitiesOnly=yes"#
        process.environment = env
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        // Arguments: git push -u origin branchName
        process.arguments = ["git", "push", "-u", "origin", branchName]

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                return (true, output)
            } else {
                return (false, error.isEmpty ? "Unknown error pushing branch" : error)
            }
        } catch {
            return (false, "Failed to push branch: \(error.localizedDescription)")
        }
    }
}
