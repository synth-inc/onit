//
//  SettingsAuthCTA.swift
//  Onit
//
//  Created by Loyd Kim on 7/22/25.
//

import SwiftUI

struct SettingsAuthCTA: View {
    @Environment(\.appState) var appState

    private let title: String
    private let caption: String

    init(
        title: String = "Sign Up to Access All Providers!",
        caption: String,
    ) {
        self.title = title
        self.caption = caption
    }

    private var isLoggedIn: Bool {
        appState.account != nil
    }

    var body: some View {
        if !isLoggedIn {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .styleText(
                        size: 13,
                        weight: .regular
                    )

                Text(caption)
                    .styleText(
                        size: 12,
                        weight: .regular,
                        color: Color.primary.opacity(0.65)
                    )

                HStack(alignment: .center, spacing: 8) {
                    GeneralTabAccount.createAnAccountButton
                    GeneralTabAccount.signInButton
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.systemGray900)
            .addBorder(
                cornerRadius: 6,
                stroke: .systemGray800
            )
        }
    }
}
