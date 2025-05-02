//
//  FreeLimitAlert.swift
//  Onit
//
//  Created by Loyd Kim on 5/2/25.
//

import SwiftUI

struct FreeLimitAlert: View {
    @Environment(\.appState) var appState
    
    var body: some View {
        SubscriptionAlert(
            title: "Free Limit Reached",
            close: { appState.showFreeLimitAlert = false },
            description: "You have used your free requests for this month.",
            subscriptionText: "Upgrade to Pro!",
            perks: [
                "⭐️ 1000 generations",
                "⭐️ Access to all features",
                "⭐️ Priority support"
            ],
            footerSupportingText: "Next renewal: 25 Apr 2025"
        )
    }
}
