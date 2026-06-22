//
//  MenuBarApp.swift
//  Onit
//
//  Created by Loyd Kim on 4/28/26.
//

import AppKit

final class MenuBarApp: MenuBarItemBase {
    // MARK: - Initializer

    override func initializeProperties() {
        self.title = ""
        self.action = #selector(openSettingsWindow)
        self.keyEquivalent = ""
        self.target = self
    }

    override func runPostInitilizationSetup() {
        self.title = String.localized("Settings", table: "MenuBar")
    }

    // MARK: - Private Functions

    @MainActor
    @objc private func openSettingsWindow() {
        SettingsWindowManager.shared.showWindow()
    }
}
