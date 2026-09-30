//
//  LucidApp.swift
//  Lucid
//
//  Created by Yuri Maciel on 30/09/26.
//

import SwiftUI

@main
struct LucidApp: App {
    @State private var stateManager = StateManager()
    @State private var launchAtLoginManager = LaunchAtLoginManager()

    var body: some Scene {
        MenuBarExtra(
            "Lucid",
            systemImage: stateManager.isActive ? "eye.fill" : "eye.slash.fill"
        ) {
            MenuBarContentView(stateManager: stateManager, launchAtLoginManager: launchAtLoginManager)
        }
    }
}
