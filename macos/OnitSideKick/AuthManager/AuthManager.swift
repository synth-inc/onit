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
    
    // MARK: - Published Properties

    @Published private(set) var account: Account? = nil
    @Published var isRestoringSession: Bool = true

    /// First and last name from Google sign-in, if available. Used to pre-fill display name fields.
    @Published private(set) var googleFirstName: String? = nil
    @Published private(set) var googleLastName: String? = nil
    
    // MARK: - Public Variables
    
    var userLoggedIn: Bool {
        self.account != nil
    }
    
    // MARK: - Public Methods
    
    func setAccount(account: Account?) {
        self.account = account
        if account != nil {
            FirebaseAuthService.shared.signIn()
        }
    }

    func logout() {
        // Reset all chat state.
        for windowState in PanelStateCoordinator.shared.states {
            windowState.newChat(clearContext: true)
        }

        Defaults[.onboardingAuthSkipped] = false
        TokenManager.token = nil
        self.account = nil
        GIDSignIn.sharedInstance.signOut()
        FirebaseAuthService.shared.signOut()
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

        FirebaseAuthService.shared.signIn()
    }
    
    // MARK: - Google Log In
    
    func logInWithGoogle() async -> String? {
        let provider = "google"
        
        AnalyticsManager.Auth.pressed(provider: provider)
        
        guard let window = NSApp.keyWindow else { return String.localized("Failed to open Google sign in", table: "Onboarding") }

        AnalyticsManager.Auth.requested(provider: provider)
        
        /// `GIDSignIn.sharedInstance.signIn` is an asynchronous callback-based function, so, by wrapping it
        ///     in `withCheckedContinuation`, we can suspend it until each callback completes and either return the proper
        ///     error message or `nil` (success).
        /// This is useful for when we want the UI to properly capture error messages.
        return await withCheckedContinuation { continuation in
            nonisolated(unsafe) var didAlreadyFinish: Bool = false
            
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
                        let errorMsg = String.localized("Unknown Google sign in error", table: "Onboarding")
                        AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
                        return finish(errorMsg)
                    }
                }

                guard let idToken = result.user.idToken?.tokenString else {
                    let errorMsg = String.localized("Failed to get Google identity token", table: "Onboarding")
                    AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
                    return finish(errorMsg)
                }

                let givenName = result.user.profile?.givenName
                let familyName = result.user.profile?.familyName

                Task { @MainActor in
                    do {
                        let loginResponse = try await FetchingClient().loginGoogle(idToken: idToken)
                        self.googleFirstName = givenName
                        self.googleLastName = familyName
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
            return String.localized("Failed to get Apple identity token", table: "Onboarding")
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
