//
//  OnboardingWindowView.swift
//  Onit
//
//  Created by Kévin Naudin on 28/11/2025.
//

import Defaults
import SwiftUI

struct OnboardingWindowView: View {
    // MARK: - Defaults

    @Default(.currentOnboardingStep) var currentStep
    @Default(.onboardingAuthSkipped) var onboardingAuthSkipped

    // MARK: - Properties

    @ObservedObject private var localization = LocalizationManager.shared
    private let windowManager = OnboardingWindowManager.shared

    // MARK: - States

    @ObservedObject private var authManager = AuthManager.shared

    // MARK: - Body

    var body: some View {
        windowPage
            .id(localization.currentLanguage)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Backgrounds.BrushedGlass())
            .cornerRadius(22)
            .ignoresSafeArea(.container, edges: .top)
            .onChange(of: authManager.userLoggedIn) { _, isLoggedIn in
                if isLoggedIn {
                    if windowManager.authOnly {
                        windowManager.closeWindow()
                    } else if currentStep == nil {
                        updateToValidStepView()
                    }
                }
            }
            .onChange(of: self.currentStep) { _, currentStep in
                if currentStep == .complete {
                    handleOnboardingComplete()
                }
            }
    }

    // MARK: - Child Components

    @ViewBuilder
    private var windowPage: some View {
        if authManager.isRestoringSession {
            // Blank during session restore (brief) — no loading page, and avoids
            // flashing the auth page before the restored session resolves.
            EmptyView()
        } else if !authManager.userLoggedIn && (!onboardingAuthSkipped || windowManager.authOnly) {
            OnboardingAuth()
        } else if let currentStep = self.currentStep {
            switch currentStep {
            /// Common Steps
            case .permissions:
                OnboardingPermissions()

            case .complete:
                EmptyView()
            }
        } else {
            EmptyView()
        }
    }

    // MARK: - Private Functions

    private func updateToValidStepView() {
        currentStep = OnboardingStep.steps.first
    }

    private func handleOnboardingComplete() {
        if !Defaults[.mainOnboardingCompleted] {
            NotificationWindowManager.shared.createWindow(
                titleKey: String.localized("Onit is up and running!", table: "Onboarding"),
                captionKey: String.localized("You're all set to use Onit.", table: "Onboarding"),
                primaryAction: (
                    textKey: String.localized("Ok", table: "Onboarding"),
                    shouldCloseWindow: true,
                    callback: nil
                ),
                enterAnimation: NotificationWindowAnimation(direction: .right),
                dismissAnimation: NotificationWindowAnimation(direction: .right)
            )

            Defaults[.mainOnboardingCompleted] = true
        }

        windowManager.closeWindow()
    }
}
