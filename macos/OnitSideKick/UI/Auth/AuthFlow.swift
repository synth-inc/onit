//
//  AuthFlow.swift
//  Onit
//
//  Created by Loyd Kim on 4/30/25.
//

import Defaults
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

struct AuthFlow: View {

    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    @Default(.authFlowStatus) var authFlowStatus
    @Default(.availableLocalModels) var availableLocalModels

    @Default(.useOpenAI) var useOpenAI
    @Default(.useAnthropic) var useAnthropic
    @Default(.useXAI) var useXAI
    @Default(.useGoogleAI) var useGoogleAI
    @Default(.useDeepSeek) var useDeepSeek
    @Default(.usePerplexity) var usePerplexity

    @State private var modelProvidersManager = ModelProvidersManager.shared

    @State private var isHoveredRedirectButton: Bool = false
    @State private var isHoveredSkipButton: Bool = false

    @State private var errorMessageAuth: String = ""
    @State private var isLoadingGoogleAuth: Bool = false
    @State private var showBlameGoogle: Bool = false

    private var isSignUp: Bool {
        authFlowStatus == .showSignUp
    }

    private var hasLocalModels: Bool {
        !availableLocalModels.isEmpty
    }

    private var hasModels: Bool {
        modelProvidersManager.userHasRemoteAPITokens || hasLocalModels
    }

    var body: some View {
        VStack(alignment: .center, spacing: 42) {
            form
            redirectCTA
            Spacer()
            closeButton
        }
        .onAppear {
            AnalyticsManager.Auth.opened()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 134)
        .id(localization.currentLanguage)
    }
}

// MARK: - Child Components

extension AuthFlow {
    private var formAuthButtons: some View {
        VStack(spacing: 4) {
            OnboardingAuthButton(
                icon: .logoGoogle,
                action: {
                    errorMessageAuth = ""
                    isLoadingGoogleAuth = true
                    showBlameGoogle = false

                    // Show blame text after 2 seconds if still loading
                    let blameTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        if isLoadingGoogleAuth {
                            showBlameGoogle = true
                        }
                    }

                    Task { @MainActor in
                        if let errorMessage = await authManager.logInWithGoogle() {
                            errorMessageAuth = errorMessage
                        }
                        isLoadingGoogleAuth = false
                        showBlameGoogle = false
                        blameTask.cancel()
                    }
                }
            )

            if isLoadingGoogleAuth {
                VStack(spacing: 2) {
                    Text(String.localized("(give it ~5 seconds)", table: "Sidekick"))
                        .styleText(size: 12, weight: .regular, color: Color.S_2, align: .center)
                    if showBlameGoogle {
                        Text(String.localized("(this is Google's fault, not ours)", table: "Sidekick"))
                            .styleText(size: 12, weight: .regular, color: Color.S_2, align: .center)
                    }
                }
            } else if !errorMessageAuth.isEmpty {
                Text(errorMessageAuth)
                    .styleText(size: 12, weight: .medium, color: Color.red500, align: .center)
            }
        }
    }
    
    private var form: some View {
        VStack(alignment: .center, spacing: 0) {
            Image("Logo").padding(.bottom, 19)

            VStack(alignment: .center, spacing: 8) {
                Text(String.localized(isSignUp ? "Create your account" : "Sign in to Onit", table: "Sidekick"))
                    .styleText(size: 23, align: .center)

                Text(String.localized("Sign up to access 30+ models from OpenAI, Anthropic & more!", table: "Sidekick"))
                    .styleText(size: 15, weight: .regular, color: Color.S_1, align: .center)
            }
            .padding(.bottom, 24)
            .frame(width: 291)

            formAuthButtons
        }
        .padding(.horizontal, 40)
    }
    
    private var redirectSection: some View {
        HStack(spacing: 6) {
            Text(String.localized(isSignUp ? "Already have an account?" : "Don't have an account yet?", table: "Sidekick"))
                .styleText(size: 13, weight: .regular, color: Color.S_1, align: .center)

            Button {
                if isSignUp {
                    authFlowStatus = .showSignIn
                } else {
                    authFlowStatus = .showSignUp
                }
            } label: {
                Text(String.localized(isSignUp ? "Sign In" : "Sign up", table: "Sidekick"))
                    .styleText(size: 13, weight: .regular, underline: isHoveredRedirectButton)
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { isHovering in
                isHoveredRedirectButton = isHovering
            }
        }
    }
    
    private var redirectCTA: some View {
        VStack(alignment: .center, spacing: 10) {
            redirectSection
            
            if authFlowStatus == .showSignUp {
                Button {
                    authFlowStatus = .hideAuth
                } label: {
                    Text(generateSkipText())
                        .styleText(size: 13, weight: .regular, align: .center, underline: isHoveredSkipButton)
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { isHovering in
                    isHoveredSkipButton = isHovering
                }
            }
        }
    }
    
    @ViewBuilder
    private var closeButton: some View {
        if !authManager.userLoggedIn && hasModels {
            TextButton(
                type: .clear,
                text: String.localized("Close", table: "Sidekick"),
                statusConfig: .init(
                    fillContainer: true
                )
            ) {
                authFlowStatus = .hideAuth
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 53)
        }
    }
}


// MARK: - Private Functions (UI)

extension AuthFlow {
    private func generateSkipText() -> AttributedString {
        var skipText = AttributedString("")

        var orText = AttributedString(String.localized("or, ", table: "Sidekick"))
        orText.foregroundColor = Color.S_1
        skipText.append(orText)

        var mainText = AttributedString(String.localized("skip account creation & use own APIs →", table: "Sidekick"))
        mainText.foregroundColor = Color.S_0
        skipText.append(mainText)

        return skipText
    }
}

