//
//  MenuJoinDiscord.swift
//  Onit
//
//  Created by OpenAI Codex on 2024.
//

import SwiftUI

struct MenuJoinDiscord: View {
    static let link = "https://discord.gg/U5g6ABkv"

    var body: some View {
        MenuBarRow {
            if let url = URL(string: Self.link) {
                NSWorkspace.shared.open(url)
            }
        } leading: {
            Text("Join Discord")
                .padding(.horizontal, 10)
        } trailing: {
            Image(.smallChevRight)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 6, height: 6)
        }
    }
}

#if DEBUG
#Preview {
    MenuJoinDiscord()
}
#endif
