//
//  SettingsAuthCTA.swift
//  Onit
//
//  Created by Loyd Kim on 7/22/25.
//

import SwiftUI

struct SettingsAuthCTA: View {
    @Environment(\.appState) var appState

    @ObservedObject private var authManager = AuthManager.shared

    private let title: String
    private let caption: String

    private static var defaultTitle: String {
        String.localized("Sign Up to Access All Providers!", table: "Models")
    }

    init(
        title: String? = nil,
        caption: String
    ) {
        self.title = title ?? Self.defaultTitle
        self.caption = caption
    }

    var body: some View {
        if !authManager.userLoggedIn {
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
                    AuthHelpers.createAnAccountButton {
                        AuthHelpers.openPanel()
                    }
                    AuthHelpers.signInButton {
                        AuthHelpers.openPanel()
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.T_9)
            .addBorder(
                cornerRadius: 6,
                stroke: Color.genericBorder
            )
        }
    }
}
