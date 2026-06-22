//
//  OnboardingStep.swift
//  Onit
//
//  Created by Kévin Naudin on 28/11/2025.
//

import Defaults
import KeyboardShortcuts

@MainActor
enum OnboardingStep: String, CaseIterable, Codable, Defaults.Serializable {
    // MARK: - Step Cases

    /// Common Steps
    case permissions
    case discord

    case complete

    // MARK: - Feature-Specific Steps

    static let commonSteps: [OnboardingStep] = [
        .permissions,
        .discord
    ]

    // MARK: - Onboarding Steps

    /// Builds the onboarding flow dynamically, based on enabled features.
    static var steps: [OnboardingStep] {
        let mainOnboardingCompleted = Defaults[.mainOnboardingCompleted]

        /// Computations
        var result: [OnboardingStep] = []

        if !mainOnboardingCompleted {
            result.append(.permissions)
            result.append(.discord)
        }

        result.append(.complete)

        return result
    }

    // MARK: - Navigation

    func nextStep() -> OnboardingStep? {
        let steps = Self.steps
        guard let currentStepIndex = steps.firstIndex(of: self) else { return nil }
        let nextStepIndex = currentStepIndex + 1
        return nextStepIndex < steps.count ? steps[nextStepIndex] : nil
    }

    func previousStep() -> OnboardingStep? {
        let steps = Self.steps
        guard let currentStepIndex = steps.firstIndex(of: self) else { return nil }
        let previousStepIndex = currentStepIndex - 1
        return previousStepIndex >= 0 ? steps[previousStepIndex] : nil
    }

    // MARK: - Step Adjustment

    /// Returns a valid step when the current step belongs to a disabled feature.
    func getNextValidOnboardingStep() -> OnboardingStep? {
        if self == .complete {
            /// Check for feature-specific onboarding, even if main onboarding is complete/dismissed.
            if let firstStep = Self.steps.first,
               firstStep != .complete
            {
                return firstStep
            }
            /// Otherwise, onboarding complete. No adjustment needed.
            else {
                return .complete
            }
        }

        /// Currently in a valid step in the onboarding flow. No adjustment needed.
        if Self.steps.contains(self) {
            return self
        }

        /// If we've hit this point, it means we're in an invalid step.
        /// Redirect to the first valid step in the current flow.
        return Self.steps.first ?? .complete
    }

    // MARK: - Feature-Specific Helpers

    var isFirstStep: Bool {
        self == Self.steps.first
    }

    /// Every step, other than the one `.complete` step, is conditional.
    /// If none of them exist in `OnboardingStep.steps`, it means that we shouldn't show the onboarding flow.
    /// Using `count`, in case future definitions of a "completed" onboarding change.
    static var isOnboardingComplete: Bool {
        return OnboardingStep.steps.count == 1
    }

    // MARK: - Display Properties

    var title: String {
        switch self {
        /// Common Steps
        case .permissions:
            return String.localized("Grant access to use Onit", table: "Onboarding")
        case .discord:
            return String.localized("Join our Discord Server!", table: "Onboarding")

        case .complete:
            return String.localized("Onit is up and running", table: "Onboarding")
        }
    }

    var caption: String {
        switch self {
        /// Common Steps
        case .permissions:
            return "Permissions are needed for Onit to work properly."
        case .discord:
            return String.localized("Say hello to the team and other Onit users, get updates\nand give feedback.", table: "Onboarding")

        case .complete:
            return String.localized("You're all set to use Onit.", table: "Onboarding")
        }
    }
}
