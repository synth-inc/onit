//
//  MenuJoinDiscord.swift
//  Onit
//
//  Created by OpenAI Codex on 2024.
//

import SwiftUI

struct MenuJoinDiscord: View {
    static let link = "https://discord.gg/2E8WWkvGYZ"

    var body: some View {
        MenuBarRow {
            if let url = URL(string: Self.link) {
                NSWorkspace.shared.open(url)
            }
        } leading: {
            Text("Join Discord →")
                .padding(.horizontal, 10)
        }
    }
}

#if DEBUG
#Preview {
    MenuJoinDiscord()
}
#endif
