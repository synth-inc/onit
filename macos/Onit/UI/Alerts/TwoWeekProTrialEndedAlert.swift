//
//  TwoWeekProTrialEndedAlert.swift
//  Onit
//
//  Created by Loyd Kim on 5/2/25.
//

import SwiftUI

struct TwoWeekProTrialEndedAlert: View {
    var body: some View {
        SubscriptionAlert(
            title: "Your 2-week Pro trial has ended",
            description: "Downgrade to free plan →",
            descriptionAction: downgradeToFreePlan,
            subscriptionText: "Continue with Pro!",
            perks: [
                "⭐️ 1000 generations",
                "⭐️ Access to all features",
                "⭐️ Priority support"
            ]
        )
    }
}

// MARK: - Private Functions

extension TwoWeekProTrialEndedAlert {
    private func downgradeToFreePlan() {
        print("DOWNGRADE TO FREE PLAN")
    }
}
