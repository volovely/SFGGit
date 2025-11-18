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
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")

        // Environment with custom SSH command
        var env = ProcessInfo.processInfo.environment
        env["GIT_SSH_COMMAND"] = #"ssh -i "# + sshKeyPath + #" -o IdentitiesOnly=yes"#
        process.environment = env
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        // Arguments: git push origin
        process.arguments = ["git", "push", "origin"]

        // Capture output
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print(output)
            }
        } catch {
            print("Failed to run process:", error)
            return false
        }
        
        return true
    }
}
