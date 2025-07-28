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
    
    // MARK: - Public Variables
    
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
    
    func logInWithGoogle() async -> String? {
        let provider = "google"
        
        AnalyticsManager.Auth.pressed(provider: provider)
        
        guard let window = NSApp.keyWindow else { return "Failed to open Google sign in" }

        AnalyticsManager.Auth.requested(provider: provider)
        
        /// `GIDSignIn.sharedInstance.signIn` is an asynchronous callback-based function, so, by wrapping it
        ///     in `withCheckedContinuation`, we can suspend it until each callback completes and either return the proper
        ///     error message or `nil` (success).
        /// This is useful for when we want the UI to properly capture error messages.
        return await withCheckedContinuation { continuation in
            var didAlreadyFinish: Bool = false
            
            func finish(_ errorMessage: String?) {
                guard !didAlreadyFinish else { return } /// Ensures that we only ever `finish()` once.
                didAlreadyFinish = true
                continuation.resume(returning: errorMessage)
            }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: window) { result, error in
                guard let result = result else {
                    if let error = error as? NSError, error.domain == "com.google.GIDSignIn", error.code == -5 {
                        // The user canceled the sign-in flow
                        AnalyticsManager.Auth.cancelled(provider: provider)
                        return finish(nil)
                    } else if let error = error {
                        let errorMsg = error.localizedDescription
                        AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
                        return finish(errorMsg)
                    } else {
                        let errorMsg = "Unknown Google sign in error"
                        AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
                        return finish(errorMsg)
                    }
                }

                guard let idToken = result.user.idToken?.tokenString else {
                    let errorMsg = "Failed to get Google identity token"
                    AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
                    return finish(errorMsg)
                }

                Task { @MainActor in
                    do {
                        let loginResponse = try await FetchingClient().loginGoogle(idToken: idToken)
                        self.handleLogin(provider: provider, loginResponse: loginResponse)
                        return finish(nil)
                    } catch {
                        let errorMsg = error.localizedDescription
                        AnalyticsManager.Auth.failed(provider: provider, error: errorMsg)
                        return finish(errorMsg)
                    }
                }
            }
        }
    }
    
    // MARK: - Apple Login
    
    func logInWithApple(_ authResults: ASAuthorization) async -> String? {
        guard
            let credentials = authResults.credential as? ASAuthorizationAppleIDCredential,
            let identityToken = credentials.identityToken,
            let identityTokenString = String(data: identityToken, encoding: .utf8)
        else {
            return "Failed to get Apple identity token"
        }
        
        do {
            let loginResponse = try await FetchingClient().loginApple(idToken: identityTokenString)
            handleLogin(provider: "Apple", loginResponse: loginResponse)
            return nil
        } catch {
            return error.localizedDescription
        }
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
