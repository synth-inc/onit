//
//  OnboardingWindowManager.swift
//  Onit
//
//  Created by Kévin Naudin on 28/11/2025.
//

import Defaults
import SwiftUI

@MainActor
class OnboardingWindowManager: NSObject, NSWindowDelegate, ObservableObject {
    // MARK: - Singleton

    static let shared = OnboardingWindowManager()

    // MARK: - States

    @ObservationIgnored
    private var _window: OnboardingWindow? = nil

    /// Public accessor for the onboarding window
    var window: OnboardingWindow? { _window }
    
    @Published private(set) var onboardingWindowIsVisible: Bool = false

    /// When true, the window will close after successful authentication instead of continuing onboarding
    @Published private(set) var authOnly: Bool = false

    // MARK: - Public Functions

    func showWindow() {
        authOnly = false
        Defaults[.onboardingAuthSkipped] = false
        if let existingWindow = _window {
            showExistingWindow(existingWindow)
        } else {
            createWindow()
        }
    }

    /// Shows onboarding starting from a specific step (for late feature activation)
    func showWindow(startingAt step: OnboardingStep) {
        authOnly = false
        Defaults[.currentOnboardingStep] = step
        showWindow()
    }

    /// Shows only the auth screen, closing the window after successful authentication.
    /// Does NOT modify currentOnboardingStep to preserve the user's onboarding progress.
    func showAuthOnly() {
        authOnly = true
        if let existingWindow = _window {
            showExistingWindow(existingWindow)
        } else {
            createWindow()
        }
    }

    func closeWindow() {
        _window?.close()
    }

    // MARK: - Private Functions

    private func showExistingWindow(_ window: OnboardingWindow) {
        if !window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            window.makeKeyAndOrderFront(nil)
        }
        onboardingWindowIsVisible = true
    }

    private func createWindow() {
        _window = OnboardingWindow()

        guard let window = _window else { return }

        window.delegate = self
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindowIsVisible = true
    }

    // MARK: - NSWindowDelegate Protocol Conformance

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? OnboardingWindow,
              window === self._window
        else {
            return
        }

        // Track onboarding dismissal (only if not in authOnly mode)
        if !authOnly {
            let currentStep = Defaults[.currentOnboardingStep]
            let stepName = currentStep?.rawValue ?? "unknown"
            let completed = currentStep == .complete

            AnalyticsManager.Onboarding.dismissed(step: stepName, completed: completed)
        }

        window.cleanupObservers()
        window.delegate = nil
        self._window = nil
        onboardingWindowIsVisible = false
    }
}
