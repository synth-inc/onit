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
    
    @Default(.authFlowStatus) var authFlowStatus
    
    @State private var showDeleteAccountAlert: Bool = false
    @State private var accountDeleteError: String = ""
    
    var body: some View {
        SettingsSection(
            iconText: "􀉪",
            title: "Account"
        ) {
            VStack(alignment: .leading) {
                if appState.account == nil { loggedOutText }
                else { loggedInText }
                
                HStack(spacing: 9) {
                    if appState.account == nil {
                        Self.createAnAccountButton
                        Self.signInButton
                    } else {
                        logoutButton
                        deleteAccountButton
                    }
                }
                
                if !accountDeleteError.isEmpty {
                    Text(accountDeleteError)
                        .styleText(size: 13, weight: .regular, color: Color.red500)
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
                color: Color.S_1
            )
    }
    
    private var loggedOutText: some View {
        text(text: "Create an account to access all features and use models without APIs!")
    }
    
    private var loggedInText: some View {
        HStack(spacing: 4) {
            if let email = appState.account?.email {
                text(text: "You are signed in as")
                text(text: email, weight: .semibold)
            } else if let appleEmail = appState.account?.appleEmail {
                text(text: "You are signed in as")
                text(text: appleEmail, weight: .semibold)
            } else {
                text(text: "Signed in.")
            }
        }
    }
    
    static var createAnAccountButton: some View {
        SimpleButton(
            iconSystem: "person.crop.circle",
            iconColor: Color.white,
            text: "Create an account",
            textColor: Color.white,
            action: {
                AnalyticsManager.AccountEvents.createAccountPressed()
                authFlowStatus = .showSignUp
                Self.openPanel()
            },
            background: Color.blue
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
                logout()
            }
        )
    }
    
    private var deleteAccountButton: some View {
        SimpleButton(
            text: "Delete account",
            textColor: Color.red,
            action: {
                AnalyticsManager.AccountEvents.deletePressed()
                showDeleteAccountAlert = true
            },
            background: Color.redDisabledHover
        )
        .sheet(isPresented: $showDeleteAccountAlert) {
            GeneralTabAccountAlert(
                show: $showDeleteAccountAlert,
                logout: logout
            )
        }
    }
}

// MARK: - Private Functions

extension GeneralTabAccount {
    @MainActor
    private func logout() {
        TokenManager.token = nil
        appState.account = nil
        GIDSignIn.sharedInstance.signOut()
        
        // Reset all chat state
        for windowState in PanelStateCoordinator.shared.states {
            windowState.newChat(clearContext: true)
        }
    }
    
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
