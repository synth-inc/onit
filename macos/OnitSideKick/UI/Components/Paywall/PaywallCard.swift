//
//  PaywallCard.swift
//  Onit
//
//  Created by Kévin Naudin on 12/03/25.
//

import SwiftUI

// MARK: - Paywall Card Configuration

/// Configuration for a paywall card. Contains all the content and actions.
struct PaywallCardConfig {
    
    let title: String
    let description: String
    let ctaText: String
    let ctaAction: () -> Void
    var ctaIsLoading: Bool = false
    var analyticsName: String = ""

    // MARK: - Pre-configured Paywall Types

    /// Free limit paywall configuration
    /// - Parameters:
    ///   - freeTrialAvailable: Whether the user can start a free trial
    ///   - isLoading: Whether the CTA button should show loading state
    ///   - onCTATapped: Action when CTA button is tapped
    @MainActor
    static func freeLimit(
        freeTrialAvailable: Bool,
        isLoading: Bool = false,
        onCTATapped: @escaping () -> Void
    ) -> PaywallCardConfig {
        PaywallCardConfig(
            title: String.localized("You're out of free edits.", table: "Sidekick"),
            description: String.localized("Unlock more with a %@", table: "Sidekick", freeTrialAvailable ? String.localized("free Pro trial!", table: "Sidekick") : String.localized("Pro membership!", table: "Sidekick")),
            ctaText: freeTrialAvailable ? String.localized("Unlock for $0", table: "Sidekick") : String.localized("Upgrade to Pro", table: "Sidekick"),
            ctaAction: onCTATapped,
            ctaIsLoading: isLoading,
            analyticsName: "free_limit"
        )
    }

    /// Pro limit paywall configuration
    /// - Parameter onCTATapped: Action when CTA button is tapped
    @MainActor
    static func proLimit(onCTATapped: @escaping () -> Void) -> PaywallCardConfig {
        PaywallCardConfig(
            title: String.localized("Pro limit reached", table: "Sidekick"),
            description: String.localized("You have reached your Pro edit limit. You may be eligible for more - contact us to find out!", table: "Sidekick"),
            ctaText: String.localized("Request more edits", table: "Sidekick"),
            ctaAction: onCTATapped,
            analyticsName: "pro_limit"
        )
    }
}

// MARK: - Paywall Card View

/// A generic paywall card component that can be configured for different paywall types.
struct PaywallCard: View {
    let config: PaywallCardConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(config.title)
                .styleText(size: 16, weight: .bold)
            
            Text(config.description)
                .styleText(size: 12, weight: .medium, color: Color.T_1)
                .padding(.bottom, 4)
            
            PaywallCTAButton(
                text: config.ctaText,
                action: config.ctaAction,
                isLoading: config.ctaIsLoading
            )
            .fixedSize()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
