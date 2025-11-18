//
//  SFGGitApp.swift
//  SFGGit
//
//  Created by Roman Volovelskyi on 18/11/2025.
//

import SwiftUI

@main
struct SFGGitApp: App {
    var body: some Scene {
        MenuBarExtra("SFGGit", systemImage: "arrow.trianglehead.branch") {
            MenuBarView()
        }
        .menuBarExtraStyle(.menu)

        Window("Push Configuration", id: "push") {
            PushView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack {
            Button("Push") {
                openWindow(id: "push")
            }
            .keyboardShortcut("p", modifiers: [.command])

            Button("Settings") {
                openWindow(id: "settings")
            }
            .keyboardShortcut(",", modifiers: [.command])

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
    }
}
