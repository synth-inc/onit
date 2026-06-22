//
//  SettingsExperimental.swift
//  Onit
//
//  Created by Timothy Lenardo on 9/29/25.
//


import SwiftUI
import Defaults

struct SettingsExperimental: View {
    // MARK: - Observed Objects

    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared

    // MARK: - Body

    var body: some View {
        debugOnboardingSection
    }

    // MARK: - Child Components: Debug Onboarding Section

    private var debugOnboardingSection: some View {
        SettingsPageSection {
            SettingsPageSubsection(
                vertical: .init(
                    spacing: 8
                ),
                header: .init(
                    title: String.localized("Debug: Onboarding", table: "Settings"),
                    subtitle: String.localized("Restart the onboarding flow for testing", table: "Settings")
                )
            ) {
                Button(action: {
                    // Reset onboarding state and launch it
                    Task { @MainActor in
                        Defaults[.mainOnboardingCompleted] = false
                        Defaults[.onboardingDismissed] = false

                        Defaults[.currentOnboardingStep] = OnboardingStep.steps.first
                        OnboardingWindowManager.shared.showWindow()
                    }
                }) {
                    Text(String.localized("Launch Onboarding", table: "Settings"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .styleText(
                            size: 12,
                            weight: .medium,
                            color: .white
                        )
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
