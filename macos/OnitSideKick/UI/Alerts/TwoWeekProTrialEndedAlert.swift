//
//  TwoWeekProTrialEndedAlert.swift
//  Onit
//
//  Created by Loyd Kim on 5/2/25.
//

import Defaults
import SwiftUI

struct TwoWeekProTrialEndedAlert: View {
    @Environment(\.appState) var appState
    
    @Default(.showTwoWeekProTrialEndedAlert) var showTwoWeekProTrialEndedAlert
    @Default(.hasClosedTrialEndedAlert) var hasClosedTrialEndedAlert
    
    private let alertName = "two_week_pro_trial_ended"
    
    var body: some View {
        SubscriptionAlert(
            title: String.localized("Your 2-week Pro trial has ended", table: "Sidekick"),
            description: String.localized("Downgrade to free plan →", table: "Sidekick"),
            descriptionAction: {
                AnalyticsManager.Billing.Alert.limitationPressed(name: alertName)
                showTwoWeekProTrialEndedAlert = false
                hasClosedTrialEndedAlert = true
            },
            subscriptionText: String.localized("Continue with Pro!", table: "Sidekick"),
            subscriptionAction: {
                AnalyticsManager.Billing.Alert.subscriptionPressed(name: alertName)
            },
            showSubscriptionPerks: true
        )
        .onAppear {
            AnalyticsManager.Billing.Alert.opened(name: alertName)
        }
    }
}
