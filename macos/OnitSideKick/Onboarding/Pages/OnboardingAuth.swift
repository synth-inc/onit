//
//  OnboardingAuth.swift
//  Onit
//
//  Created by Kévin Naudin on 28/11/2025.
//

import Defaults
import SwiftUI

struct OnboardingAuth: View {
    // MARK: - Observations

    @ObservedObject private var authManager = AuthManager.shared

    // MARK: - States

    @State private var authProvider: String? = nil

    @State private var magicLinkEmail: String = ""
    @State private var magicLinkErrorMessage: String? = nil
    @State private var magicLinkRequestLoading: Bool = false
    @State private var magicLinkRequested: Bool = false

    @State private var showNoAccountFAQ: Bool = false
    
    // MARK: - Private Variables
    
    private let magicLinkProvider = "email"
    
    private var magicLinkEmailIsValid: Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: magicLinkEmail)
    }

    // MARK: - Body

    var body: some View {
        OnboardingPage(
            headerConfig: .init(paddingTop: 40),
            footerConfig: .init(
                showBackButton: magicLinkRequested,
                backButtonAction: {
                    magicLinkRequested = false
                },
                showNextButton: false
            ),
            headerContent: {
                if magicLinkRequested {
                    EmptyView()
                } else {
                    authHeaderView
                }
            },
            headerTitle: {
                EmptyView()
            },
            bodyContent: {
                if magicLinkRequested {
                    magicLinkConfirmationView
                } else {
                    VStack(alignment: .center, spacing: 20) {
                        VStack(alignment: .center, spacing: 6) {
                            Self.GoogleAuthButton(authProvider: $authProvider)
                            orDivider
                            magicLinkForm
                        }
                        noAccountSection
                    }
                    .padding(.top, 18)
                    .frame(width: 320, alignment: .center)
                }
            },
            footerContent: {
                HStack(alignment: .center) {
                    Spacer()
                }
            },
            footerCaption: {
                if magicLinkRequested {
                    magicLinkBlurb
                } else {
                    footerAgreementBlurb
                }
            }
        )
        .overlay {
            if showNoAccountFAQ {
                OnboardingNoAccountFAQOverlay(isPresented: $showNoAccountFAQ)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showNoAccountFAQ)
    }

    // MARK: - Child Components: Auth Header

    private var authHeaderView: some View {
        OnboardingTitleAndCaption(
            customTitle: String.localized("Welcome to Onit", table: "Onboarding")
        )
    }

    // MARK: - Child Components: Google Auth Button

    private struct GoogleAuthButton: View {
        @State private var errorMessage: String? = nil
        @State private var isLoading: Bool = false
        @State private var showBlameGoogle: Bool = false
        @Binding var authProvider: String?

        @State private var isHovered: Bool = false
        @State private var isPressed: Bool = false

        private func handleTap() {
            guard !isLoading else { return }
            errorMessage = nil
            isLoading = true
            showBlameGoogle = false
            authProvider = "google"

            let blameTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if isLoading { showBlameGoogle = true }
            }

            Task { @MainActor in
                if let errorMessage = await AuthManager.shared.logInWithGoogle() {
                    self.errorMessage = errorMessage
                }
                isLoading = false
                showBlameGoogle = false
                blameTask.cancel()
            }
        }

        var body: some View {
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(.logoGoogle)
                    Text(String.localized("Continue with Google", table: "Onboarding"))
                        .styleText(size: 14, weight: .medium, color: .black)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .addBorder(cornerRadius: 9, stroke: Color.genericBorder)
                .addButtonEffects(
                    background: Color.white,
                    hoverBackground: Color.white.opacity(0.85),
                    cornerRadius: 9,
                    isHovered: $isHovered,
                    isPressed: $isPressed,
                    action: handleTap
                )

                if isLoading {
                    VStack(spacing: 2) {
                        Text(String.localized("(give it ~5 seconds)", table: "Onboarding"))
                            .styleText(
                                size: 12,
                                weight: .regular,
                                color: Color.S_2,
                                align: .center
                            )
                        if showBlameGoogle {
                            Text(String.localized("(this is Google's fault, not ours)", table: "Onboarding"))
                                .styleText(
                                    size: 12,
                                    weight: .regular,
                                    color: Color.S_2,
                                    align: .center
                                )
                        }
                    }
                } else if let errorMessage {
                    Text(errorMessage)
                        .styleText(
                            size: 12,
                            color: Color.red500,
                            align: .center
                        )
                }
            }
        }
    }
    
    // MARK: - OR Divider
    
    private var orDivider: some View {
        Text(String.localized("OR", table: "Onboarding"))
            .frame(
                height: 15,
                alignment: .center
            )
            .styleText(
                size: 10,
                color: Color.S_3
            )
    }
    
    // MARK: - Child Components: Magic Link Form
    
    private var magicLinkForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            InputField(
                text: $magicLinkEmail,
                placeholder: String.localized("Email Address", table: "Onboarding"),
                errorMessage: magicLinkErrorMessage,
                colorConfig: .init(
                    border: Color.T_4
                ),
                statusConfig: .init(
                    borderDotted: true
                )
            ) {
                requestMagicLinkLogin(provider: magicLinkProvider)
            }
            
            TextButton(
                type: .primary,
                text: String.localized("Continue with email", table: "Onboarding"),
                statusConfig: .init(
                    disabled: magicLinkEmail.isEmpty || !magicLinkEmailIsValid,
                    fillContainer: true
                )
            ) {
                AnalyticsManager.Auth.pressed(provider: magicLinkProvider)
                requestMagicLinkLogin(provider: magicLinkProvider)
            }
        }
    }

    // MARK: - Child Components: Magic Link Confirmation View

    private var magicLinkConfirmationView: some View {
        VStack(alignment: .center, spacing: 0) {
            Image("Mail")
                .padding(.bottom, 22)

            Text(String.localized("Check your email", table: "Onboarding"))
                .padding(.bottom, 20)
                .styleText(
                    size: 23
                )

            VStack(alignment: .center, spacing: 2) {
                Text(String.localized("Click the link we sent to:", table: "Onboarding"))
                    .styleText(
                        size: 13,
                        weight: .regular,
                        color: Color.S_1
                    )

                Text(magicLinkEmail)
                    .styleText(
                        size: 15,
                        weight: .regular
                    )
            }
            
            if let magicLinkErrorMessage {
                Text(magicLinkErrorMessage)
                    .styleText(
                        size: 13,
                        color: Color.red500
                    )
            }
        }
        .padding(.top, 66)
    }
    
    // MARK: - Child Components: No Account Section

    private var noAccountSection: some View {
        Button {
            showNoAccountFAQ = true
        } label: {
            Text(String.localized("Do I need an account?", table: "Onboarding"))
                .styleText(size: 13, weight: .regular, color: Color.S_1, align: .center)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Child Components: Magic Link Blurb

    private var magicLinkBlurb: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(String.localized("Didn't get it? Check your spam folder and the spelling", table: "Onboarding"))
                .styleText(
                    size: 12,
                    weight: .regular,
                    color: Color.S_3
                )
            HStack(alignment: .top, spacing: 0) {
                Text(String.localized("of your email address, or ", table: "Onboarding"))
                    .styleText(
                        size: 12,
                        weight: .regular,
                        color: Color.S_3
                    )

                Button {
                    requestMagicLinkLogin(provider: magicLinkProvider)
                } label: {
                    Text(
                        magicLinkRequestLoading ?
                            String.localized("Sending...", table: "Onboarding") :
                            String.localized("Resend Link", table: "Onboarding")
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .styleText(
                    size: 12,
                    weight: .regular
                )
                .disabled(magicLinkRequestLoading)
            }
        }
    }

    // MARK: - Child Components: Footer Agreement Blurb

    private var footerAgreementBlurb: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(String.localized("By continuing, you agree to our", table: "Onboarding"))
                .styleText(
                    size: 12,
                    weight: .regular,
                    color: Color.S_3
                )

            HStack(alignment: .top, spacing: 0) {
                linkButton(
                    text: String.localized("Terms of Service", table: "Onboarding"),
                    link: "https://www.getonit.ai/terms-of-service",
                    showArrow: false
                )

                Text(String.localized(" and ", table: "Onboarding"))
                    .styleText(
                        size: 12,
                        weight: .regular,
                        color: Color.S_3
                    )

                linkButton(
                    text: String.localized("Privacy Policy", table: "Onboarding"),
                    link: "https://www.getonit.ai/privacy",
                    showArrow: false
                )
            }
        }
    }
    
    private func linkButton(
        text: String,
        link: String,
        showArrow: Bool = true
    ) -> some View {
        Button {
            if let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(alignment: .center, spacing: 4) {
                Text(text)
                    .styleText(
                        size: 12,
                        weight: .regular,
                        color: Color.S_0
                    )

                if showArrow {
                    Image(.arrowsTopRight)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Private Functions

    @MainActor
    private func requestMagicLinkLogin(provider: String) {
        authProvider = provider
        magicLinkErrorMessage = nil

        if magicLinkEmail.isEmpty {
            magicLinkErrorMessage = String.localized(
                "Please enter your email", 
                table: "Onboarding"
            )
            AnalyticsManager.Auth.error(
                provider: provider,
                error: "User did not provide an email for magic link auth."
            )
        } else if !magicLinkEmailIsValid {
            magicLinkErrorMessage = String.localized(
                "Invalid email format", 
                table: "Onboarding"
            )
            AnalyticsManager.Auth.error(
                provider: provider,
                error: "User supplied an invalid email format for magic link auth."
            )
        } else {
            Task { @MainActor in
                do {
                    AnalyticsManager.Auth.requested(provider: provider)
                    magicLinkRequestLoading = true
                    try await FetchingClient().requestLoginLink(email: magicLinkEmail)
                    magicLinkRequested = true
                    magicLinkRequestLoading = false
                } catch {
                    magicLinkErrorMessage = String.localized(
                        "Something went wrong. Please try again.", 
                        table: "Onboarding"
                    )
                    let errorDescription = "User requested a magic link login, but it failed with error: \(error.localizedDescription)"
                    print("[OnboardingAuth] \(errorDescription)")
                    AnalyticsManager.Auth.failed(
                        provider: provider,
                        error: "Magic link request failed: \(type(of: error))"
                    )
                    magicLinkRequestLoading = false
                }
            }
        }
    }
}
