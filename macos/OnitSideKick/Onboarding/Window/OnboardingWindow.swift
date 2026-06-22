//
//  OnboardingWindow.swift
//  Onit
//
//  Created by Kévin Naudin on 28/11/2025.
//

import Defaults
import SwiftUI

/// Custom NSHostingView that accepts the first mouse click without requiring window activation first
private class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

final class OnboardingWindow: CenteredWindow<OnboardingWindowView> {

    init() {
        super.init(
            rootView: OnboardingWindowView(),
            canCloseWithEsc: false,
            windowSize: (
                width: 858,
                height: 506
            ),
            titleBarButtonsOffset: (
                xOffset: 10,
                yOffset: 4
            )
        )

        // Replace content view with one that accepts first click
        let firstClickView = FirstClickHostingView(rootView: OnboardingWindowView())
        self.contentView = firstClickView
    }

    // MARK: - Overrides

    override func close() {
        // Only mark onboarding as dismissed if it was completed
        // This allows onboarding to resume after app restart
        if Defaults[.currentOnboardingStep] == .complete {
            Defaults[.onboardingDismissed] = true
        }
        
        super.close()
    }
}
