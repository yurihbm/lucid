//
//  MenuBarContentView.swift
//  Lucid
//

import SwiftUI

struct MenuBarContentView: View {
    var stateManager: StateManager

    var body: some View {
        Text(stateManager.isActive ? "menu.status.active" : "menu.status.inactive")

        Divider()

        Button(stateManager.isActive ? "menu.action.deactivate" : "menu.action.activate") {
            stateManager.toggle()
        }

        Divider()

        Button("menu.action.quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
