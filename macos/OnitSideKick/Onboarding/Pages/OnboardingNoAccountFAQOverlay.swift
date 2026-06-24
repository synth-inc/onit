//
//  OnboardingNoAccountFAQOverlay.swift
//  Onit
//

import Defaults
import SwiftUI

struct OnboardingNoAccountFAQOverlay: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            faqPanel
                .frame(width: 520)
                .padding(.horizontal, 2)
        }
    }

    // MARK: - Panel

    private var faqPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            Text(String.localized("Do I need an account?", table: "Onboarding"))
                .styleText(size: 15, weight: .medium, color: Color.S_0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)

            // Body
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(String.localized(
                        "No, you don't! You can use SideKick without an account and dictation will still be free. However, we prefer you sign-in for a few reasons:",
                        table: "Onboarding"
                    ))
                    .styleText(size: 14, weight: .regular, color: Color.T_1, align: .leading)
                    .padding(.bottom, 12)

                    VStack(alignment: .leading, spacing: 8) {
                        bulletItem(
                            bold: String.localized("Keep your free seat", table: "Onboarding"),
                            body: String.localized(
                                ". Without an account, we have no way to track free access. If we launch a paid tier down the road, you could lose your free spot when you uninstall the app, switch devices, or otherwise clear your data.",
                                table: "Onboarding"
                            )
                        )
                        bulletItem(
                            bold: String.localized("Mobile access", table: "Onboarding"),
                            body: String.localized(
                                ". We're building a mobile version of SideKick, and an account is what links your desktop and mobile experience together.",
                                table: "Onboarding"
                            )
                        )
                        bulletItem(
                            bold: String.localized("Help us improve", table: "Onboarding"),
                            body: String.localized(
                                ". Without a way to reach our users, improving the product gets a lot harder. If you want SideKick to keep getting better, an account helps us make that happen.",
                                table: "Onboarding"
                            )
                        )
                        bulletItem(
                            bold: String.localized("It's still private.", table: "Onboarding"),
                            body: String.localized(
                                " We will never share your email or data with third parties.",
                                table: "Onboarding"
                            )
                        )
                    }
                    .padding(.bottom, 12)

                    Text(String.localized(
                        "Ultimately, it's your call. Privacy matters (especially for a local dictation tool) so if you'd rather skip the account, we completely understand!",
                        table: "Onboarding"
                    ))
                    .styleText(size: 14, weight: .regular, color: Color.T_1, align: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 310)

            // Footer
            HStack(spacing: 8) {
                Spacer()
                footerButton(
                    text: String.localized("Proceed without account", table: "Onboarding")
                ) {
                    isPresented = false
                    Defaults[.onboardingAuthSkipped] = true
                    Defaults[.currentOnboardingStep] = OnboardingStep.steps.first
                }
                footerButton(
                    text: String.localized("Sign up", table: "Onboarding")
                ) {
                    isPresented = false
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay(alignment: .top) {
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.T_9)
            }
        }
        .background(Color.surface3)
        .cornerRadius(22)
        .addBorder(cornerRadius: 22, stroke: Color.T_9)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 2)
    }

    // MARK: - Bullet Item

    private func bulletItem(bold: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.system(size: 14))
                .foregroundColor(Color.T_1)
            (Text(bold).bold() + Text(body))
                .font(.system(size: 14))
                .foregroundColor(Color.T_1)
        }
    }

    // MARK: - Footer Button

    @State private var hoveredButton: String? = nil

    private func footerButton(text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .styleText(size: 14, weight: .medium, color: Color.S_0)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(hoveredButton == text ? Color.T_8 : Color.T_9)
                .cornerRadius(9)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering in
            hoveredButton = isHovering ? text : nil
        }
    }
}
