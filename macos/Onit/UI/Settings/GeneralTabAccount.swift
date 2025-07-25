//
//  GeneralTabAccount.swift
//  Onit
//
//  Created by Loyd Kim on 4/30/25.
//

import Defaults
import SwiftUI
import GoogleSignIn

struct GeneralTabAccount: View {
    @Environment(\.appState) var appState
    
    @ObservedObject private var authManager = AuthManager.shared
    
    @Default(.authFlowStatus) var authFlowStatus
    
    @State private var showDeleteAccountAlert: Bool = false
    @State private var accountDeleteError: String = ""
    
    var body: some View {
        SettingsSection(
            iconText: "􀉪",
            title: "Account"
        ) {
            VStack(alignment: .leading) {
                if !authManager.userLoggedIn { loggedOutText }
                else { loggedInText }
                
                HStack(spacing: 9) {
                    if !authManager.userLoggedIn {
                        createAnAccountButton
                        signInButton
                    } else {
                        logoutButton
                        deleteAccountButton
                    }
                }
                
                if !accountDeleteError.isEmpty {
                    Text(accountDeleteError)
                        .styleText(size: 13, weight: .regular, color: .red)
                }
            }
        }
    }
}

// MARK: - Child Components

extension GeneralTabAccount {
    private func text(
        text: String,
        weight: Font.Weight = Font.Weight.regular
    ) -> some View {
        Text(text)
            .styleText(
                size: 13,
                weight: weight,
                color: Color(hex: "#A1A4AF") ?? .gray100
            )
    }
    
    private var loggedOutText: some View {
        text(text: "Create an account to access all features and use models without APIs!")
    }
    
    private var loggedInText: some View {
        HStack(spacing: 4) {
            if let email = authManager.account?.email {
                text(text: "You are signed in as")
                text(text: email, weight: .semibold)
            } else if let appleEmail = authManager.account?.appleEmail {
                text(text: "You are signed in as")
                text(text: appleEmail, weight: .semibold)
            } else {
                text(text: "Signed in.")
            }
        }
    }
    
    private var createAnAccountButton: some View {
        SimpleButton(
            iconText: "👤",
            text: "Create an account",
            action: {
                AnalyticsManager.AccountEvents.createAccountPressed()
                authFlowStatus = .showSignUp
                Self.openPanel()
            },
            background: .blue
        )
    }
    
    private var signInButton: some View {
        SimpleButton(text: "Sign in") {
            Self.openSignInAuth()
        }
    }
    
    private var logoutButton: some View {
        SimpleButton(
            text: "Log out",
            action: {
                AnalyticsManager.AccountEvents.logoutPressed()
                authManager.logout()
            }
        )
    }
    
    private var deleteAccountButton: some View {
        SimpleButton(
            text: "Delete account",
            textColor: .red,
            action: {
                AnalyticsManager.AccountEvents.deletePressed()
                showDeleteAccountAlert = true
            },
            background: .redBrick
        )
        .sheet(isPresented: $showDeleteAccountAlert) {
            GeneralTabAccountAlert(show: $showDeleteAccountAlert)
        }
    }
}

// MARK: - Private Functions

extension GeneralTabAccount {
    static func openPanel() {
        if !PanelStateCoordinator.shared.state.panelOpened {
            PanelStateCoordinator.shared.launchPanel()
        }
    }
    
    static func openSignInAuth() {
        AnalyticsManager.AccountEvents.signInPressed()
        Defaults[.authFlowStatus] = .showSignIn
        Self.openPanel()
    }
}
