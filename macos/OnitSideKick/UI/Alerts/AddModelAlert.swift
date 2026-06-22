//
//  AddModelAlert.swift
//  Onit
//
//  Created by Loyd Kim on 8/4/25.
//

import Defaults
import SwiftUI

struct AddModelAlert: View {
    var body: some View {
        SubscriptionAlert(
            title: String.localized("Add a model to continue", table: "Sidekick"),
            description: String.localized("Connect at least one remote or local model in Settings to chat with Onit.", table: "Sidekick"),
            spacingBetweenSections: 10,
            showApiCta: false,
            footerSupportingText: String.localized("Or, sign up for free access to 30+ models from OpenAI, Anthropic and more!", table: "Sidekick")
        ) {
            HStack(alignment: .center, spacing: 8) {
                ctaButton(
                    text: String.localized("Add in Settings", table: "Sidekick"),
                    background: Color.T_7,
                    hoverBackground: Color.T_9
                ) {
                    SettingsWindowManager.shared.showWindow(page: .panelModels)
                }

                ctaButton(
                    text: String.localized("Sign up", table: "Sidekick"),
                    textColor: Color.white,
                    background: Color.blue400,
                    hoverBackground: Color.blue350
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
        textColor: Color = Color.S_0,
        background: Color,
        hoverBackground: Color,
        action: @escaping () -> Void
    ) -> some View {
        TextButton(
            text: text,
            colorConfig: .init(
                text: textColor,
                background: background,
                hoverBackground: hoverBackground
            ),
            sizeConfig: .init(
                text: 13,
                height: 32,
                cornerRadius: 6
            ),
            statusConfig: .init(
                fillContainer: true
            )
        ) {
            action()
        }
    }
}
