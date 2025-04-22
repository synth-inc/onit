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

struct AccountTab: View {
    @State private var email: String = ""
    @State private var requestedEmail: Bool = false
    @State private var token: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            if !requestedEmail {
                emailSection
            }
            if requestedEmail {
                tokenSection
            }
            google
            apple

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 12))
            }
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
                let response = try await client.loginToken(loginToken: token)
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
    }
}
