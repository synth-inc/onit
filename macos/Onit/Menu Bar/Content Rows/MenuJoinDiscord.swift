//
//  MenuJoinDiscord.swift
//  Onit
//
//  Created by OpenAI Codex on 2024.
//

import SwiftUI

struct MenuJoinDiscord: View {
    @Environment(\.appState) private var appState
    
    static let link = "https://discord.gg/2E8WWkvGYZ"

    var body: some View {
        MenuBarRow {
            Self.openDiscord(appState)
        } leading: {
            Text("Join Discord →")
                .padding(.horizontal, 10)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Static Functions

extension MenuJoinDiscord {
    static func openDiscord(_ appState: AppState) {
        if let url = URL(string: Self.link) {
            NSWorkspace.shared.open(url)
            appState.removeDiscordFooterNotifications()
        }
    }
}

#if DEBUG
#Preview {
    MenuJoinDiscord()
}
#endif
