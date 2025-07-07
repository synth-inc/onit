//
//  AuthForm.swift
//  Onit
//
//  Created by Loyd Kim on 7/7/25.
//

import AuthenticationServices
import Defaults
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

struct AuthForm: View {
    @Environment(\.appState) var appState
    
    @Default(.useOpenAI) var useOpenAI
    @Default(.useAnthropic) var useAnthropic
    @Default(.useXAI) var useXAI
    @Default(.useGoogleAI) var useGoogleAI
    @Default(.useDeepSeek) var useDeepSeek
    @Default(.usePerplexity) var usePerplexity
    
    @Default(.authFlowStatus) var authFlowStatus
    
    // MARK: - Properties
    
    @Binding private var email: String
    @Binding private var errorMessageEmail: String
    
    private var requestEmailLoginLink: () -> Void
    
    init(
        email: Binding<String>,
        errorMessageEmail: Binding<String>,
        requestEmailLoginLink: @escaping () -> Void
    ) {
        self._email = email
        self._errorMessageEmail = errorMessageEmail
        self.requestEmailLoginLink = requestEmailLoginLink
    }
    
    // MARK: - States
    
    @State private var isHoveredContinueWithEmailButton: Bool = false
    
    @State private var isPressedContinueWithEmailButton: Bool = false
    
    @State private var errorMessageAuth: String = ""
    
    // MARK: - Private Variables
    
    private var isSignUp: Bool {
        return authFlowStatus == .showSignUp
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Image("Logo").padding(.bottom, 19)
            
            Text(isSignUp ? "Create your account" : "Sign in to Onit")
                .styleText(size: 23)
                .padding(.bottom, 28)
            
            VStack(alignment: .center, spacing: 12) {
                formAuthButtons
                
                Text("OR")
                    .styleText(
                        size: 12,
                        color: .gray300
                    )
                
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        emailAddressInput
                        continueWithEmailButton
                    }
//                    agreement
                }
            }
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Child Components
    
    private var formAuthButtons: some View {
        VStack(spacing: 4) {
            OnboardingAuthButton(
                icon: .logoGoogle,
                action: handleGoogleSignInButton
            )
            
            if !errorMessageAuth.isEmpty {
                Text(errorMessageAuth)
                    .styleText(
                        size: 12,
                        weight: .medium,
                        color: .red,
                        align: .center
                    )
            }
        }
    }
    
    private var emailAddressInput: some View {
        InputField(
            placeholder: "Email Address",
            text: $email,
            errorMessage: errorMessageEmail
        ) {
            requestEmailLoginLink()
        }
    }
    
    private var continueWithEmailButton: some View {
        Text("Continue with email")
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .styleText(align: .center)
            .addButtonEffects(
                background: .blue400,
                hoverBackground: .blue350,
                cornerRadius: 9,
                isHovered: $isHoveredContinueWithEmailButton,
                isPressed: $isPressedContinueWithEmailButton
            ) {
                requestEmailLoginLink()
            }
    }
    
    private var agreement: some View {
        Text(generateAgreementText())
            .styleText(
                size: 12,
                align: .center
            )
    }
    
    // MARK: - Private Functions
    
    private func generateAgreementText() -> AttributedString {
        var agreementText = AttributedString("By continuing with Google or email, you agree to our ")
        agreementText.foregroundColor = .gray300
        
        var termsText = AttributedString("Terms of Service")
        termsText.foregroundColor = .gray200
        termsText.link = URL(string: "https://www.getonit.ai/")
        agreementText.append(termsText)
        
        var andText = AttributedString(" and ")
        andText.foregroundColor = .gray300
        agreementText.append(andText)
        
        var privacyText = AttributedString("Privacy Policy")
        privacyText.foregroundColor = .gray200
        privacyText.link = URL(string: "https://www.getonit.ai/")
        agreementText.append(privacyText)
        
        var periodText = AttributedString(".")
        periodText.foregroundColor = .gray300
        agreementText.append(periodText)
        
        return agreementText
    }
    
    @MainActor
    private func handleLogin(loginResponse: LoginResponse) {
        TokenManager.token = loginResponse.token
        appState.account = loginResponse.account

        if loginResponse.isNewAccount {
            AnalyticsManager.Identity.identify(account: loginResponse.account)
            useOpenAI = true
            useAnthropic = true
            useXAI = true
            useGoogleAI = true
            useDeepSeek = true
            usePerplexity = true
        }
    }
    
    private func handleGoogleSignInButton() {
        let provider = "google"
        AnalyticsManager.Auth.pressed(provider: provider)
        errorMessageAuth = ""
        
        guard let window = NSApp.keyWindow else { return }

        AnalyticsManager.Auth.requested(provider: provider)
        
        GIDSignIn.sharedInstance.signIn(withPresenting: window) { result, error in
            guard let result = result else {
                if let error = error as? NSError, error.domain == "com.google.GIDSignIn", error.code == -5 {
                    // The user canceled the sign-in flow
                    AnalyticsManager.Auth.cancelled(provider: provider)
                    return
                } else if let error = error {
                    let errorMsg = error.localizedDescription
                    
                    AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
                    errorMessageAuth = errorMsg
                } else {
                    let errorMsg = "Unknown Google sign in error"
                    
                    AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
                    errorMessageAuth = errorMsg
                }
                return
            }

            guard let idToken = result.user.idToken?.tokenString else {
                let errorMsg = "Failed to get Google identity token"
                
                AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
                errorMessageAuth = errorMsg
                return
            }

            Task {
                do {
                    let client = FetchingClient()
                    let loginResponse = try await client.loginGoogle(idToken: idToken)
                    handleLogin(loginResponse: loginResponse)
                    AnalyticsManager.Auth.success(provider: provider)
                } catch {
                    let errorMsg = error.localizedDescription
                    
                    AnalyticsManager.Auth.failed(provider: provider, error: errorMsg)
                    errorMessageAuth = errorMsg
                }
            }
        }
    }
    
    private func handleAppleCredential(_ authResults: ASAuthorization) async throws {
        guard
            let credentials = authResults.credential as? ASAuthorizationAppleIDCredential,
            let identityToken = credentials.identityToken,
            let identityTokenString = String(data: identityToken, encoding: .utf8)
        else {
            errorMessageAuth = "Failed to get Apple identity token"
            return
        }
        
        let client = FetchingClient()
        let loginResponse = try await client.loginApple(idToken: identityTokenString)
        handleLogin(loginResponse: loginResponse)
    }
}
