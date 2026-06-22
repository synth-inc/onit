//
//  AppModeCoordinator.swift
//  Onit
//
//  Created by Kévin Naudin on 28/11/2025.
//

import Combine
import Defaults
import Foundation

/// Delegate protocol for AppModeCoordinator state changes
@MainActor
protocol AppModeCoordinatorDelegate: AnyObject {
    /// Called when Panel (Sidebar) mode state changes
    func appModeCoordinator(_ coordinator: AppModeCoordinator, didChangePanelState enabled: Bool)
}

/// Centralized coordinator for managing the Panel mode
/// Handles lifecycle, service dependencies, and state synchronization
@MainActor
final class AppModeCoordinator: ObservableObject {

    // MARK: - Shared Instance

    static let shared = AppModeCoordinator()

    // MARK: - Delegate

    weak var delegate: AppModeCoordinatorDelegate?

    // MARK: - State

    /// Current Panel (Sidebar) enabled state
    var isPanelEnabled: Bool {
        Defaults[.enableSidebar]
    }

    // MARK: - Services

    private var panelCancellable: AnyCancellable?

    // MARK: - Initialization

    private init() {
        setupObservers()
    }

    // MARK: - Public Interface

    /// Cleanup resources on app termination
    func cleanup() {
        panelCancellable?.cancel()
    }

    // MARK: - Panel Control

    /// Enable Panel (Sidebar) mode
    func enablePanel() {
        guard !isPanelEnabled else { return }
        Defaults[.enableSidebar] = true
    }

    /// Disable Panel (Sidebar) mode
    func disablePanel() {
        guard isPanelEnabled else { return }
        Defaults[.enableSidebar] = false
    }

    // MARK: - Private Helpers

    private func setupObservers() {
        // Observer for Panel (Sidebar) state changes
        panelCancellable = Defaults.publisher(.enableSidebar)
            .map(\.newValue)
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.delegate?.appModeCoordinator(self, didChangePanelState: enabled)
                }
            }
    }

    // MARK: - Onboarding Helpers

    /// Launches onboarding if not dismissed and not completed
    func launchOnboardingIfNeeded() {
        let onboardingDismissed = Defaults[.onboardingDismissed]
        let currentStep = Defaults[.currentOnboardingStep]

        // Safety check: if onboarding was marked as dismissed but step is not complete,
        // it means the app was force-quit.
        // Reset the dismissed flag to allow onboarding to resume.
        if onboardingDismissed && currentStep != .complete {
            Defaults[.onboardingDismissed] = false
        }

        // Safety check: if current step belongs to a disabled feature, skip to an appropriate step
        Defaults[.currentOnboardingStep] = currentStep?.getNextValidOnboardingStep()

        guard !OnboardingStep.isOnboardingComplete else { return }

        OnboardingWindowManager.shared.showWindow()
    }
}
