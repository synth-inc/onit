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
    var body: some View {
        VStack(spacing: 24) {
            google
            apple
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
                    print(error)
                } else {
                    print("Unknown Google sign in error")
                }
                return
            }

            guard let idToken = result.user.idToken?.tokenString else {
                print("Couldn't get Google identity token")
                return
            }

            Task {
                let client = FetchingClient()
                let loginResponse = try await client.loginGoogle(idToken: idToken)
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
                        try await handleAppleCredential(authResult)
                    }
                case .failure(let error):
                    print(error)
                }
            }
    }
    
    func handleAppleCredential(_ authResults: ASAuthorization) async throws {
        guard
            let credentials = authResults.credential as? ASAuthorizationAppleIDCredential,
            let identityToken = credentials.identityToken,
            let identityTokenString = String(data: identityToken, encoding: .utf8)
        else { return }
        
        let client = FetchingClient()
        let loginResponse = try await client.loginApple(idToken: identityTokenString)
    }
}
