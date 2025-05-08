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
    
    @Default(.showOnboardingSignUp) var showOnboardingSignUp
    
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
            action: { Defaults[.showOnboardingSignUp] = true },
            background: .blue
        )
    }
    
    private var signInButton: some View {
        SimpleButton(
            text: "Sign in",
            action: { Defaults[.showOnboardingSignUp] = false }
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
        .alert(
            "Are you sure you want to delete your account?",
            isPresented: $showDeleteAccountAlert
        ) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteAccount() }
        } message: {
            Text("This action cannot be undone.")
                .styleText(size: 11, weight: .regular)
        }
    }
}

// MARK: - Private Functions

extension GeneralTabAccount {
    @MainActor
    private func logout() {
        TokenManager.token = nil
        appState.account = nil
        Defaults[.showOnboardingSignUp] = false
    }
    
    @MainActor
    private func deleteAccount() {
        accountDeleteError = ""
        let client = FetchingClient()
        
        Task {
            do {
                try await client.deleteAccount()
                logout()
            } catch {
                accountDeleteError = error.localizedDescription
            }
        }
    }
}
