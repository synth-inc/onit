//
//  SettingsAuthCTA.swift
//  Onit
//
//  Created by Loyd Kim on 6/26/25.
//

import SwiftUI

struct SettingsAuthCTA: View {
    @Environment(\.appState) var appState
    
    private let title: String
    private let caption: String
    private let fitContainer: Bool
    
    init(
        title: String = "Sign Up to Access All Providers!",
        caption: String,
        fitContainer: Bool = false
    ) {
        self.title = title
        self.caption = caption
        self.fitContainer = fitContainer
    }
    
    private var isLoggedIn: Bool {
        appState.account != nil
    }
    
    var body: some View {
        if !isLoggedIn {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .styleText(
                        size: 13
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
            .padding(.horizontal, fitContainer ? 0 : 8)
            .padding(.vertical, fitContainer ? 0 : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fitContainer ? .clear : .systemGray900)
            .addBorder(
                cornerRadius: 6,
                stroke: fitContainer ? .clear : .systemGray800
            )
        }
    }
}
