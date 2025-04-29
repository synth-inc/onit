//
//  AccountTab.swift
//  Onit
//
//  Created by Jason Swanson on 4/22/25.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import Defaults

struct AccountTab: View {
    @Environment(\.appState) var appState

    @State private var email: String = ""
    @State private var requestedEmail: Bool = false
    @State private var token: String = ""
    @State private var loginPassword: String = ""

    @Default(.useOnitChat) var useOnitChat
    @State private var setPassword: String = ""

    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            if appState.account == nil {
                if !requestedEmail {
                    emailSection
                    loginPasswordSection
                }
                if requestedEmail {
                    tokenSection
                }
                google
                apple
            } else {
                useOnitChatSection
                setPasswordSection
                logoutButton
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 12))
            }
        }
        .onChange(of: appState.account == nil) { _, _ in
            email = ""
            requestedEmail = false
            token = ""
            loginPassword = ""
            setPassword = ""
            errorMessage = nil
        }
    }
    
    var emailSection: some View {
        VStack(spacing: 12) {
            TextField("Enter your email", text: $email)
            Button("Request Magic Link") {
                handleLoginLinkRequest()
            }
            .disabled(email.isEmpty)
        }
    }

    func handleLoginLinkRequest() {
        let client = FetchingClient()
        Task {
            do {
                try await client.requestLoginLink(email: email)
                requestedEmail = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    var loginPasswordSection: some View {
        VStack(spacing: 12) {
            SecureField("Password", text: $loginPassword)
            Button("Login") {
                Task {
                    await handleLoginPassword(email: email, loginPassword: loginPassword)
                }
            }
            .disabled(loginPassword.isEmpty)
        }
    }

    func handleLoginPassword(email: String, loginPassword: String) async {
        do {
            let client = FetchingClient()
            let loginResponse = try await client.loginPassword(email: email, password: loginPassword)
            handleLogin(loginResponse: loginResponse)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var tokenSection: some View {
        VStack(spacing: 12) {
            TextField("Enter your login token", text: $token)
            Button("Login") {
                handleTokenLogin()
            }
            .disabled(token.isEmpty)
        }
    }

    func handleTokenLogin() {
        let client = FetchingClient()
        Task {
            do {
                let loginResponse = try await client.loginToken(loginToken: token)
                handleLogin(loginResponse: loginResponse)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    var google: some View {
        GoogleSignInButton(action: handleGoogleSignInButton)
    }

    func handleGoogleSignInButton() {
        guard let window = NSApp.keyWindow else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: window) { result, error in
            guard let result = result else {
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    errorMessage = "Unknown Google sign in error"
                }
                return
            }

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get Google identity token"
                return
            }

            Task {
                do {
                    let client = FetchingClient()
                    let loginResponse = try await client.loginGoogle(idToken: idToken)
                    handleLogin(loginResponse: loginResponse)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    var apple: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.email]
            }) { result in
                switch result {
                case .success(let authResult):
                    Task {
                        do {
                            try await handleAppleCredential(authResult)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
    }
    
    func handleAppleCredential(_ authResults: ASAuthorization) async throws {
        guard
            let credentials = authResults.credential as? ASAuthorizationAppleIDCredential,
            let identityToken = credentials.identityToken,
            let identityTokenString = String(data: identityToken, encoding: .utf8)
        else {
            errorMessage = "Failed to get Apple identity token"
            return
        }
        
        let client = FetchingClient()
        let loginResponse = try await client.loginApple(idToken: identityTokenString)
        handleLogin(loginResponse: loginResponse)
    }
    
    func handleLogin(loginResponse: LoginResponse) {
        TokenManager.token = loginResponse.token
        appState.account = loginResponse.account
    }
    
    var useOnitChatSection: some View {
        HStack {
            Text("Use Onit Chat")
                .font(.system(size: 13))
            Spacer()
            Toggle("", isOn: $useOnitChat)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }

    var setPasswordSection: some View {
        VStack(spacing: 12) {
            SecureField("Create a password", text: $setPassword)
            Button("Set Your Password") {
                Task {
                    await handleSetPassword(setPassword: setPassword)
                }
            }
            .disabled(setPassword.isEmpty)
        }
    }
    
    func handleSetPassword(setPassword: String) async {
        do {
            let client = FetchingClient()
            try await client.updatePassword(password: setPassword)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    var logoutButton: some View {
        Button("Logout") {
            handleLogout()
        }
    }
    
    func handleLogout() {
        TokenManager.token = nil
        appState.account = nil
    }
}
