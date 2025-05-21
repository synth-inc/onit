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
    @Default(.showOnboarding) var showOnboarding
    
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
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 134)
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
                    .styleText(size: 12, weight: .medium, color: .red, align: .center)
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
            .styleText(align: .center)
            .addButtonEffects(
                action: requestEmailLoginLink,
                background: .blue400,
                hoverBackground: .blue350,
                cornerRadius: 9,
                isHovered: $isHoveredContinueWithEmailButton,
                isPressed: $isPressedContinueWithEmailButton
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
                
                Text("OR").styleText(size: 12, color: .gray300)
                
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
            .styleText(size: 12, align: .center)
    }
    
    private var redirectSection: some View {
        HStack(spacing: 6) {
            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                .styleText(size: 13, weight: .regular, color: .gray100)
            
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
                showOnboarding = false
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
                        color: .gray100
                    )
                
                Text(email).styleText(size: 15, weight: .regular)
            }
            .padding(.vertical, 16)
            
            Spacer()
            
            VStack(alignment: .center, spacing: 28) {
                VStack(alignment: .center, spacing: 0) {
                    Text("Didn't get it? Check your spam folder and the spelling")
                        .styleText(size: 12, color: .gray200, align: .center)
                        .frame(maxWidth: .infinity)
                    
                    HStack(spacing: 4) {
                        Text("of your email address, or")
                            .styleText(size: 12, color: .gray200)
                        
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
                    .background(isHoveredBackButton ? .gray900 : .clear)
                    .addBorder(cornerRadius: 9, stroke: .gray700)
                    .scaleEffect(isPressedBackButton ? 0.98 : 1)
                    .opacity(isPressedBackButton ? 0.7 : 1)
                    .addAnimation(dependency: isHoveredBackButton)
                    .onHover{ isHovering in isHoveredBackButton = isHovering }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged {_ in isPressedBackButton = true }
                            .onEnded{ _ in
                                isPressedBackButton = false
                                requestedEmailLogin = false
                            }
                    )
            }
        }
        .padding(.bottom, 53)
    }
}


// MARK: - Private Functions (UI)

extension AuthFlow {
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
    
    private func generateSkipText() -> AttributedString {
        var skipText = AttributedString("")
        
        var orText = AttributedString("or, ")
        orText.foregroundColor = .gray100
        skipText.append(orText)
        
        var mainText = AttributedString("skip account creation & use own APIs →")
        mainText.foregroundColor = Color.primary
        skipText.append(mainText)
        
        return skipText
    }
    
    @MainActor
    private func handleLogin(loginResponse: LoginResponse) {
        TokenManager.token = loginResponse.token
        appState.account = loginResponse.account
        
        if loginResponse.isNewAccount {
            useOpenAI = true
            useAnthropic = true
            useXAI = true
            useGoogleAI = true
            useDeepSeek = true
            usePerplexity = true
        }
        
        authFlowStatus = .hideAuth
        showOnboarding = false
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
        errorMessageEmail = ""

        if email.isEmpty {
            errorMessageEmail = "Please enter your email"
        } else if !validateEmail() {
            errorMessageEmail = "Invalid email format"
        } else {
            let client = FetchingClient()
            
            Task {
                do {
                    try await client.requestLoginLink(email: email)
                    requestedEmailLogin = true
                } catch {
                    errorMessageEmail = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Private Functions (Google, Apple)

extension AuthFlow {
    private func handleGoogleSignInButton() {
        errorMessageAuth = ""
        
        guard let window = NSApp.keyWindow else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: window) { result, error in
            guard let result = result else {
                if let error = error as? NSError, error.domain == "com.google.GIDSignIn", error.code == -5 {
                    // The user canceled the sign-in flow
                    return
                } else if let error = error {
                    errorMessageAuth = error.localizedDescription
                    PostHog.shared.capture("google_sign_in_error", properties: [
                        "error": error.localizedDescription
                    ])
                } else {
                    errorMessageAuth = "Unknown Google sign in error"
                    PostHog.shared.capture("google_sign_in_error", properties: [
                        "error": "Unknown error"
                    ])
                }
                return
            }

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessageAuth = "Failed to get Google identity token"
                return
            }

            Task {
                do {
                    let client = FetchingClient()
                    let loginResponse = try await client.loginGoogle(idToken: idToken)
                    handleLogin(loginResponse: loginResponse)
                } catch {
                    errorMessageAuth = error.localizedDescription
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
