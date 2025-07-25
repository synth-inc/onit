//
//  AuthManager.swift
//  Onit
//
//  Created by Loyd Kim on 7/25/25.
//

import AuthenticationServices
import Defaults
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

@MainActor
final class AuthManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = AuthManager()
    
    // MARK: - Properties
    
    @Published private(set) var account: Account? = nil
    
    // MARK: - Variables
    
    var userLoggedIn: Bool {
        self.account != nil
    }
    
    // MARK: - Public Methods
    
    func setAccount(account: Account?) {
        self.account = account
    }
    
    func logout() {
        TokenManager.token = nil
        self.account = nil
        GIDSignIn.sharedInstance.signOut()
        
        // Reset all chat state
        for windowState in PanelStateCoordinator.shared.states {
            windowState.newChat(clearContext: true)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleLogin(provider: String, loginResponse: LoginResponse) {
        TokenManager.token = loginResponse.token
        self.account = loginResponse.account

        if loginResponse.isNewAccount {
            AnalyticsManager.Identity.identify(account: loginResponse.account)
            
            Defaults[.useOpenAI] = true
            Defaults[.useAnthropic] = true
            Defaults[.useXAI] = true
            Defaults[.useGoogleAI] = true
            Defaults[.useDeepSeek] = true
            Defaults[.usePerplexity] = true
        }
        
        AnalyticsManager.Auth.success(provider: provider)
        
        Defaults[.authFlowStatus] = .hideAuth
    }
    
    // MARK: - Google Log In
    
    func logInWithGoogle() -> String? {
        let provider = "google"
        
        AnalyticsManager.Auth.pressed(provider: provider)
        
        guard let window = NSApp.keyWindow else { return "Failed to open Google sign in" }

        AnalyticsManager.Auth.requested(provider: provider)
        
        var GIDSignInErrorMessage: String? = nil
        
        GIDSignIn.sharedInstance.signIn(withPresenting: window) { result, error in
            guard let result = result else {
                if let error = error as? NSError, error.domain == "com.google.GIDSignIn", error.code == -5 {
                    // The user canceled the sign-in flow
                    AnalyticsManager.Auth.cancelled(provider: provider)
                    return
                } else if let error = error {
                    let errorMsg = error.localizedDescription
                    GIDSignInErrorMessage = errorMsg
                    
                    AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
                } else {
                    let errorMsg = "Unknown Google sign in error"
                    GIDSignInErrorMessage = errorMsg
                    
                    AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
                }
                return
            }

            guard let idToken = result.user.idToken?.tokenString else {
                let errorMsg = "Failed to get Google identity token"
                GIDSignInErrorMessage = errorMsg
                
                AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
                return
            }

            Task {
                do {
                    let loginResponse = try await FetchingClient().loginGoogle(idToken: idToken)
                    
                    self.handleLogin(provider: provider, loginResponse: loginResponse)

                    AnalyticsManager.Auth.success(provider: provider)
                } catch {
                    let errorMsg = error.localizedDescription
                    GIDSignInErrorMessage = errorMsg
                    
                    AnalyticsManager.Auth.failed(provider: provider, error: errorMsg)
                }
            }
        }
        
        return GIDSignInErrorMessage
    }
    
    // MARK: - Apple Login
    
    func logInWithApple(_ authResults: ASAuthorization) async throws -> String? {
        guard
            let credentials = authResults.credential as? ASAuthorizationAppleIDCredential,
            let identityToken = credentials.identityToken,
            let identityTokenString = String(data: identityToken, encoding: .utf8)
        else {
            return "Failed to get Apple identity token"
        }
        
        var errorMessage: String? = nil
        
        do {
            let loginResponse = try await FetchingClient().loginApple(idToken: identityTokenString)
            
            handleLogin(provider: "Apple", loginResponse: loginResponse)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        return errorMessage
    }

    
    // MARK: - Magic Link Login
    
    func handleTokenLogin(_ url: URL) {
        guard url.scheme == "onit" else {
            return
        }
        
        let provider = "email"
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            let errorMsg = "Invalid URL"
            
            AnalyticsManager.Auth.failed(provider: provider, error: errorMsg)
            print(errorMsg)
            return
        }

        guard let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
            let errorMsg = "Login token not found"
            
            AnalyticsManager.Auth.failed(provider: provider, error: errorMsg)
            print(errorMsg)
            return
        }

        Task { @MainActor in
            do {
                let loginResponse = try await FetchingClient().loginToken(loginToken: token)
                
                handleLogin(provider: provider, loginResponse: loginResponse)
            } catch {
                AnalyticsManager.Auth.failed(provider: provider, error: error.localizedDescription)
                print("Login by token failed with error: \(error)")
            }
        }
    }
}
