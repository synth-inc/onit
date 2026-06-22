//
//  MenuBarQuit.swift
//  Onit
//
//  Created by Loyd Kim on 9/19/25.
//

import AppKit

final class MenuBarQuit: MenuBarItemBase {
    // MARK: - Initializer

    override func initializeProperties() {
        self.title = ""
        self.action = #selector(quitApp)
        self.keyEquivalent = ""
        self.target = self
    }

    override func runPostInitilizationSetup() {
        self.title = String.localized("Quit", table: "MenuBar")
    }

    // MARK: - Private Functions

    @MainActor
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
