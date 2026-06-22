//
//  SettingsSidekickModels.swift
//  Onit
//
//  Created by Kévin Naudin on 12/04/2025.
//

import SwiftUI

struct SettingsSidekickModels: View {
    // MARK: - Environment

    @Environment(\.appState) var appState

    // MARK: - Body

    var body: some View {
        SettingsAuthCTA(
            caption: String.localized("Create an account to access all remote providers and use models like GPT-4o, Gemini, Grok and more without API Keys.", table: "Sidekick")
        )

        DividerHorizontal()
            .padding(.vertical, 6)

        RemoteModelsSection()

        DividerHorizontal()
            .padding(.vertical, 6)

        LocalModelsSection()

        DividerHorizontal()
            .padding(.vertical, 6)

        DefaultModelsSection()
    }
}
