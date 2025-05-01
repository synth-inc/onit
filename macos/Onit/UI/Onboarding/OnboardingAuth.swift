//
//  OnboardingAuth.swift
//  Onit
//
//  Created by Loyd Kim on 4/30/25.
//

import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift
import Defaults
import SwiftUI

struct OnboardingAuth: View {
    @Environment(\.appState) var appState
    
    @Default(.showOnboardingSignUp) var showOnboardingSignUp
    
    private let isSignUp: Bool
    init(isSignUp: Bool) { self.isSignUp = isSignUp }
    
    @FocusState private var isFocusedInput: Bool
    @State private var isHoveredInput: Bool = false
    @State private var isPressedInput: Bool = false
    
    @State private var email: String = ""
    @State private var loginPassword: String = ""
    @State private var requestedEmailLogin: Bool = false
    @State private var emailLoginToken: String = ""
    
    @State private var errorMessageEmail: String = ""
    @State private var errorMessageAuth: String? = nil
    
    @State private var token: String = ""
    @State private var isHoveredBackButton: Bool = false
    @State private var isPressedBackButton: Bool = false
    @State private var errorMessageToken: String = ""
    
    var submitDisabled: Bool {
        return email.isEmpty || !errorMessageEmail.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 42) {
            if requestedEmailLogin {
                emailAuthTokenForm
            } else {
                form
                if isSignUp { signUpRedirect }
                else { redirectSection }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 134)
    }
}

// MARK: - Child Components

extension OnboardingAuth {
    private var formAuthButtons: some View {
        VStack(spacing: 4) {
//            HStack(spacing: 12) {
//                OnboardingAuthButton(
//                    icon: .logoGoogle,
//                    action: handleGoogleSignInButton
//                )
//                
//                OnboardingAuthButton(
//                    icon: .logoApple,
//                    action: { print("Apple Auth") }
//                )
//            }
//            .frame(width: 188)
            
            OnboardingAuthButton(
                icon: .logoGoogle,
                action: handleGoogleSignInButton
            )
            
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
                                errorMessageAuth = error.localizedDescription
                            }
                        }
                    case .failure(let error):
                        errorMessageAuth = error.localizedDescription
                    }
                }
                .frame(height: 40)
                .styleText(size: 16)
                .addBorder(cornerRadius: 9, stroke: .gray700)
            
            if let errorMessageAuth = errorMessageAuth {
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
        .onChange(of: email) { _, currentEmail in
            if currentEmail.isEmpty {
                errorMessageEmail = "Please enter your email"
            } else if !validateEmail(email: currentEmail) {
                errorMessageEmail = "Invalid email format"
            } else {
                errorMessageEmail = ""
            }
        }
    }
    
    private var continueWithEmailButton: some View {
        TextButton(
            action: requestEmailLoginLink,
            height: 40,
            cornerRadius: 9,
            background: .blue400,
            hoverBackground: .blue350
        ) {
            Text("Continue with email")
                .frame(maxWidth: .infinity, alignment: .center)
                .styleText(weight: .regular)
        }
        .opacity(submitDisabled ? 0.5 : 1)
        .allowsHitTesting(!submitDisabled)
        .addAnimation(dependency: submitDisabled)
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
                    showOnboardingSignUp = false
                } else {
                    showOnboardingSignUp = true
                }
            } label: {
                Text(isSignUp ? "Sign In" : "Sign up")
                    .styleText(size: 13, weight: .regular)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var signUpRedirect: some View {
        VStack(alignment: .center, spacing: 12) {
            redirectSection
            
            HStack(spacing: 3) {
                Text("or,")
                    .styleText(size: 13, weight: .regular, color: .gray100)
                
                Button {
                    showOnboardingSignUp = nil
                } label: {
                    Text("skip account creation & use own APIs →")
                        .styleText(size: 13, weight: .regular)
                }
            }
        }
    }
    
    private var emailAuthTokenForm: some View {
        VStack(alignment: .center, spacing: 0) {
            Image("Mail").padding(.bottom, 16)
            
            Text("Check your email")
                .styleText(size: 23)
            
            VStack(alignment: .center, spacing: 2) {
                Text("Click the link we sent to:").styleText(size: 13, color: .gray100)
                Text(email).styleText(size: 15, weight: .regular)
            }
            .padding(.vertical, 16)
            
            VStack(spacing: 12) {
                InputField(
                    placeholder: "Token",
                    text: $token,
                    errorMessage: errorMessageToken,
                    onSubmit: handleTokenLogin
                )
                
                TextButton(
                    action: handleTokenLogin,
                    height: 40,
                    cornerRadius: 9,
                    background: .blue400,
                    hoverBackground: .blue350
                ) {
                    Text("Continue with token")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .styleText(weight: .regular)
                }
                .opacity(token.isEmpty ? 0.5 : 1)
                .allowsHitTesting(!token.isEmpty)
                .addAnimation(dependency: token)
            }
            .padding(.horizontal, 40)
            
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
                                .styleText(size: 12)
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
                                token = ""
                                errorMessageToken = ""
                                requestedEmailLogin = false
                            }
                    )
            }
        }
        .padding(.bottom, 53)
    }
}


// MARK: - Private Functions (UI)

extension OnboardingAuth {
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
        showOnboardingSignUp = nil
    }
}

// MARK: - Private Functions (email)

extension OnboardingAuth {
    private func validateEmail(email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isValidEmailFormat = emailTest.evaluate(with: email)
        return isValidEmailFormat
    }
    
    private func requestEmailLoginLink() {
        if !submitDisabled {
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

extension OnboardingAuth {
    private func handleGoogleSignInButton() {
        guard let window = NSApp.keyWindow else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: window) { result, error in
            guard let result = result else {
                if let error = error {
                    errorMessageAuth = error.localizedDescription
                } else {
                    errorMessageAuth = "Unknown Google sign in error"
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

// MARK: - Private Functions (onboarding auth token form)

extension OnboardingAuth {
    private func handleTokenLogin() {
        let client = FetchingClient()
        Task {
            do {
                let loginResponse = try await client.loginToken(loginToken: token)
                handleLogin(loginResponse: loginResponse)
            } catch {
                errorMessageToken = error.localizedDescription
            }
        }
    }
}
