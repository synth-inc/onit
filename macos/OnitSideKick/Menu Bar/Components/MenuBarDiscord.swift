//
//  MenuBarDiscord.swift
//  Onit
//
//  Created by Loyd Kim on 9/19/25.
//

import AppKit

@MainActor
final class MenuBarDiscord: MenuBarItemBase {
    // MARK: - Initializer

    override func initializeProperties() {
        self.title = ""
        self.action = #selector(handleOpenDiscord)
        self.keyEquivalent = ""
        self.target = self
    }

    override func runPostInitilizationSetup() {
        self.title = String.localized("Join Discord", table: "MenuBar")
    }

    // MARK: - Private Functions

    static func openDiscord() {
        let link = "https://discord.gg/2E8WWkvGYZ"

        if let url = URL(string: link) {
            NSWorkspace.shared.open(url)
            AppState.shared.removeDiscordFooterNotifications()
        }
    }

    @objc private func handleOpenDiscord() {
        Self.openDiscord()
    }
}
