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
    private var loggedOutText: some View {
        Text("Create an account to access all features and use models without APIs!")
            .styleText(size: 13, weight: .regular, color: .gray100)
    }
    
    private var loggedInText: some View {
        HStack(spacing: 4) {
            if let email = appState.account?.email {
                Text("You are signed in as").styleText(size: 13, weight: .regular, color: .gray100)
                Text(email).styleText(size: 13, weight: .bold, color: .gray100)
            } else if let appleEmail = appState.account?.appleEmail {
                Text("You are signed in as").styleText(size: 13, weight: .regular, color: .gray100)
                Text(appleEmail).styleText(size: 13, weight: .bold, color: .gray100)
            } else {
                Text("Signed in.").styleText(size: 13, weight: .regular, color: .gray100)
            }
        }
    }
    
    private var createAnAccountButton: some View {
        Button {
            Defaults[.showOnboardingSignUp] = true
        } label: {
            HStack(alignment: .center, spacing: 2) {
                Text("👤").styleText(size: 11, weight: .regular)
                Text("Create an account").styleText(size: 13, weight: .regular)
            }
        }
        .buttonStyle(DefaultButtonStyle())
        .background(.blue)
        .cornerRadius(5)
    }
    
    private var signInButton: some View {
        Button {
            Defaults[.showOnboardingSignUp] = false
        } label: {
            Text("Sign in").styleText(size: 13, weight: .regular)
        }
        .buttonStyle(DefaultButtonStyle())
    }
    
    private var logoutButton: some View {
        Button {
            logout()
        } label: {
            Text("Log out").styleText(size: 13, weight: .regular)
        }
        .buttonStyle(DefaultButtonStyle())
    }
    
    private var deleteAccountButton: some View {
        Button {
            showDeleteAccountAlert = true
        } label: {
            Text("Delete account").styleText(size: 13, color: .red)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: 22)
        .padding(.horizontal, 7)
        .background(.redBrick)
        .cornerRadius(5)
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
