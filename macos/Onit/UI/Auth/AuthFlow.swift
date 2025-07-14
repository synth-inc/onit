//
//  AuthFlow.swift
//  Onit
//
//  Created by Loyd Kim on 4/30/25.
//

import AuthenticationServices
import Defaults
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

struct AuthFlow: View {
    @Environment(\.appState) var appState
    
    @Default(.authFlowStatus) var authFlowStatus
    @Default(.availableLocalModels) var availableLocalModels
    
    @Default(.useOpenAI) var useOpenAI
    @Default(.useAnthropic) var useAnthropic
    @Default(.useXAI) var useXAI
    @Default(.useGoogleAI) var useGoogleAI
    @Default(.useDeepSeek) var useDeepSeek
    @Default(.usePerplexity) var usePerplexity

    @State private var isHoveredContinueWithEmailButton: Bool = false
    @State private var isPressedContinueWithEmailButton: Bool = false
    
    @State private var isHoveredRedirectButton: Bool = false
    @State private var isHoveredSkipButton: Bool = false

    @State private var isHoveredResendLinkButton: Bool = false
    @State private var isHoveredBackButton: Bool = false
    @State private var isPressedBackButton: Bool = false
    
    @State private var email: String = ""
    @State private var requestedEmailLogin: Bool = false
    
    @State private var errorMessageEmail: String = ""
    @State private var errorMessageAuth: String = ""
    
    private var isSignUp: Bool {
        return authFlowStatus == .showSignUp
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 42) {
            if requestedEmailLogin {
                emailAuthTokenForm
            } else {
                form
                redirectSection
                Spacer()
                closeButton
            }
        }
        .onAppear {
            AnalyticsManager.Auth.opened()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 134)
        .background(Color.baseBG)
    }
}

// MARK: - Child Components

extension AuthFlow {
    private var formAuthButtons: some View {
        VStack(spacing: 4) {
            OnboardingAuthButton(
                icon: .logoGoogle,
                action: handleGoogleSignInButton
            )
            
            if !errorMessageAuth.isEmpty {
                Text(errorMessageAuth)
                    .styleText(size: 12, weight: .medium, color: Color.red500, align: .center)
            }
        }
    }
    
    private var emailAddressInput: some View {
        InputField(
            placeholder: "Email Address",
            text: $email,
            errorMessage: errorMessageEmail,
            onSubmit: requestEmailLoginLink
        )
    }
    
    private var continueWithEmailButton: some View {
        Text("Continue with email")
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .styleText(color: Color.white, align: .center)
            .addButtonEffects(
                background: Color.blue400,
                hoverBackground: Color.blue350,
                cornerRadius: 9,
                isHovered: $isHoveredContinueWithEmailButton,
                isPressed: $isPressedContinueWithEmailButton,
                action: requestEmailLoginLink
            )
    }
    
    private var form: some View {
        VStack(alignment: .center, spacing: 0) {
            Image("Logo").padding(.bottom, 19)
            
            Text(isSignUp ? "Create your account" : "Sign in to Onit")
                .styleText(size: 23)
                .padding(.bottom, 28)
            
            VStack(alignment: .center, spacing: 12) {
                formAuthButtons
                
                Text("OR").styleText(size: 12, color: Color.S_3)
                
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
    
    private var agreement: some View {
        Text(generateAgreementText())
            .frame(width: 320)
            .styleText(size: 12, align: .center)
    }
    
    private var redirectSection: some View {
        HStack(spacing: 6) {
            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                .styleText(size: 13, weight: .regular, color: Color.S_1)
            
            Button {
                if isSignUp {
                    authFlowStatus = .showSignIn
                } else {
                    authFlowStatus = .showSignUp
                }
            } label: {
                Text(isSignUp ? "Sign In" : "Sign up")
                    .styleText(size: 13, weight: .regular, underline: isHoveredRedirectButton)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovering in
                isHoveredRedirectButton = isHovering
            }
        }
    }
    
    private var signUpRedirect: some View {
        VStack(alignment: .center, spacing: 12) {
            redirectSection
            
            Button {
                authFlowStatus = .hideAuth
            } label: {
                Text(generateSkipText())
                    .styleText(size: 13, weight: .regular, underline: isHoveredSkipButton)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovering in
                isHoveredSkipButton = isHovering
            }
        }
    }
    
    private var emailAuthTokenForm: some View {
        VStack(alignment: .center, spacing: 0) {
            Image("Mail").padding(.bottom, 16)
            
            Text("Check your email")
                .styleText(size: 23)
            
            VStack(alignment: .center, spacing: 2) {
                Text("Click the link we sent to:")
                    .styleText(
                        size: 13,
                        weight: .regular,
                        color: Color.S_1
                    )
                
                Text(email).styleText(size: 15, weight: .regular)
            }
            .padding(.vertical, 16)
            
            Spacer()
            
            VStack(alignment: .center, spacing: 28) {
                VStack(alignment: .center, spacing: 0) {
                    Text("Didn't get it? Check your spam folder and the spelling")
                        .styleText(size: 12, color: Color.S_2, align: .center)
                        .frame(maxWidth: .infinity)
                    
                    HStack(spacing: 4) {
                        Text("of your email address, or")
                            .styleText(size: 12, color: Color.S_2)
                        
                        Button {
                            requestEmailLoginLink()
                        } label: {
                            Text("Resend Link")
                                .styleText(size: 12, underline: isHoveredResendLinkButton)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onHover { isHovering in
                            isHoveredResendLinkButton = isHovering
                        }
                    }
                }
                
                Text("← Back")
                    .frame(height: 40)
                    .padding(.horizontal, 14)
                    .background(isHoveredBackButton ? Color.T_8 : Color.T_9)
                    .addBorder(cornerRadius: 9, stroke: Color.genericBorder)
                    .scaleEffect(isPressedBackButton ? 0.98 : 1)
                    .opacity(isPressedBackButton ? 0.7 : 1)
                    .addAnimation(dependency: isHoveredBackButton)
                    .onHover{ isHovering in isHoveredBackButton = isHovering }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged {_ in isPressedBackButton = true }
                            .onEnded{ _ in
                                AnalyticsManager.Auth.cancelled(provider: "email")
                                isPressedBackButton = false
                                requestedEmailLogin = false
                            }
                    )
            }
        }
        .padding(.bottom, 53)
    }
    
    @ViewBuilder
    private var closeButton: some View {
        let hasRemoteModels = appState.hasUserAPITokens
        let hasLocalModels = !availableLocalModels.isEmpty
        let hasModels = hasRemoteModels || hasLocalModels
        
        if !appState.userLoggedIn && hasModels {
            TextButton(height: 40) {
                Text("Close")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .styleText()
            } action: {
                authFlowStatus = .hideAuth
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 53)
        }
    }
}


// MARK: - Private Functions (UI)

extension AuthFlow {
    private func generateAgreementText() -> AttributedString {
        var agreementText = AttributedString("By continuing with Google or email, you agree to our ")
        agreementText.foregroundColor = Color.S_3
        
        var termsText = AttributedString("Terms of Service")
        termsText.foregroundColor = Color.S_2
        termsText.link = URL(string: "https://www.getonit.ai/")
        agreementText.append(termsText)
        
        var andText = AttributedString(" and ")
        andText.foregroundColor = Color.S_3
        agreementText.append(andText)
        
        var privacyText = AttributedString("Privacy Policy")
        privacyText.foregroundColor = Color.S_2
        privacyText.link = URL(string: "https://www.getonit.ai/")
        agreementText.append(privacyText)
        
        var periodText = AttributedString(".")
        periodText.foregroundColor = Color.S_3
        agreementText.append(periodText)
        
        return agreementText
    }
    
    private func generateSkipText() -> AttributedString {
        var skipText = AttributedString("")
        
        var orText = AttributedString("or, ")
        orText.foregroundColor = Color.S_1
        skipText.append(orText)
        
        var mainText = AttributedString("skip account creation & use own APIs →")
        mainText.foregroundColor = Color.S_0
        skipText.append(mainText)
        
        return skipText
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
        
        authFlowStatus = .hideAuth
    }
}

// MARK: - Private Functions (email)

extension AuthFlow {
    private func validateEmail() -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isValidEmailFormat = emailTest.evaluate(with: email)
        return isValidEmailFormat
    }
    
    @MainActor
    private func requestEmailLoginLink() {
        let provider = "email"
        AnalyticsManager.Auth.pressed(provider: provider)
        
        errorMessageEmail = ""

        if email.isEmpty {
            let errorMsg = "Please enter your email"
            
            AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
            errorMessageEmail = errorMsg
        } else if !validateEmail() {
            let errorMsg = "Invalid email format"
            
            AnalyticsManager.Auth.error(provider: provider, error: errorMsg)
            errorMessageEmail = errorMsg
        } else {
            let client = FetchingClient()
            
            Task {
                do {
                    AnalyticsManager.Auth.requested(provider: provider)
                    try await client.requestLoginLink(email: email)
                    requestedEmailLogin = true
                } catch {
                    let errorMsg = error.localizedDescription
                    
                    AnalyticsManager.Auth.failed(provider: provider, error: errorMsg)
                    errorMessageEmail = errorMsg
                }
            }
        }
    }
}

// MARK: - Private Functions (Google, Apple)

extension AuthFlow {
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
