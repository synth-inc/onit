//
//  AddModelAlert.swift
//  Onit
//
//  Created by Loyd Kim on 8/4/25.
//

import Defaults
import SwiftUI

struct AddModelAlert: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings
    
    var body: some View {
        SubscriptionAlert(
            title: "Add a model to continue",
            description: "Connect at least one remote or local model in Settings to chat with Onit.",
            spacingBetweenSections: 10,
            showApiCta: false,
            footerSupportingText: "Or, sign up for free access to 30+ models from OpenAI, Anthropic and more!"
        ) {
            HStack(alignment: .center, spacing: 8) {
                ctaButton(
                    text: "Add in Settings",
                    background: .gray500,
                    hoverBackground: .gray400
                ) {
                    appState.settingsTab = .models
                    openSettings()
                }
                
                ctaButton(
                    text: "Sign up",
                    background: .blue400,
                    hoverBackground: .blue350
                ) {
                    Defaults[.authFlowStatus] = .showSignUp
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: Child Components
    
    private func ctaButton(
        text: String,
        background: Color,
        hoverBackground: Color,
        action: @escaping () -> Void
    ) -> some View {
        TextButton(
            fillContainer: false,
            cornerRadius: 6,
            background: background,
            hoverBackground: hoverBackground
        ) {
            Text(text)
                .frame(maxWidth: .infinity)
                .styleText(size: 13, weight: .regular, align: .center)
        } action: {
            action()
        }
    }
}
