//
//  AuthHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 4/30/25.
//

import Defaults
import SwiftUI

// MARK: - Auth Helper Functions

@MainActor
enum AuthHelpers {
    static func createAnAccountButton(callback: (() -> Void)? = nil) -> some View {
        SimpleButton(
            iconSystem: "person.crop.circle",
            iconColor: Color.white,
            text: String.localized("Create an account"),
            textColor: Color.white,
            action: {
                AnalyticsManager.AccountEvents.createAccountPressed()
                Defaults[.authFlowStatus] = .showSignUp
                callback?()
            },
            background: Color.blue
        )
    }

    static func signInButton(callback: (() -> Void)? = nil) -> some View {
        SimpleButton(text: String.localized("Sign in")) {
            AnalyticsManager.AccountEvents.signInPressed()
            Defaults[.authFlowStatus] = .showSignIn
            callback?()
        }
    }

    static var logoutButton: some View {
        SimpleButton(
            text: String.localized("Log out"),
            action: {
                AnalyticsManager.AccountEvents.logoutPressed()
                AuthManager.shared.logout()
            }
        )
    }

    static func openPanel() {
        if !PanelStateCoordinator.shared.state.panelOpened {
            PanelStateCoordinator.shared.launchPanel()
        }
    }

    enum OpenAuthCategory {
        case signIn
        case signUp
    }

    static func openAuth(for category: OpenAuthCategory = .signIn) {
        if category == .signIn {
            AnalyticsManager.AccountEvents.signInPressed()
            Defaults[.authFlowStatus] = .showSignIn
        } else {
            AnalyticsManager.AccountEvents.signUpPressed()
            Defaults[.authFlowStatus] = .showSignUp
        }

        openPanel()
    }
}
