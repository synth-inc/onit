//
//  GeneralTabAccount.swift
//  Onit
//
//  Created by Loyd Kim on 4/30/25.
//

import Defaults
import SwiftUI

struct GeneralTabAccount: View {
    @Environment(\.appState) var appState
    @Environment(\.openWindow) private var openWindow
    
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
    
    private var createAnAccountButton: some View {
        SimpleButton(
            iconText: "👤",
            text: "Create an account",
            action: {
                authFlowStatus = .showSignUp
                openPanel()
            },
            background: .blue
        )
    }
    
    private var signInButton: some View {
        SimpleButton(
            text: "Sign in",
            action: {
                authFlowStatus = .showSignIn
                openPanel()
            }
        )
    }
    
    private var logoutButton: some View {
        SimpleButton(
            text: "Log out",
            action: logout
        )
    }
    
    private var deleteAccountButton: some View {
        SimpleButton(
            text: "Delete account",
            textColor: .red,
            action: { showDeleteAccountAlert = true },
            background: .redBrick
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
        Defaults[.authFlowStatus] = .showSignIn
    }
    
    private func openPanel() {
        let coordinator = PanelStateCoordinator.shared
        
        // Open the pinned panel, if it isn't already open, so that the user can see the auth flow forms.
        if coordinator.state.panel == nil {
            if let currentScreen = NSScreen.main ?? NSScreen.mouse {
                let manager = PanelStatePinnedManager.shared
                
                manager.hideTetherWindow()
                coordinator.state.trackedScreen = currentScreen
                coordinator.state.launchPanel()
            }
        }
    }
}
