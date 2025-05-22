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
            title: "Your 2-week Pro trial has ended",
            description: "Downgrade to free plan →",
            descriptionAction: {
                AnalyticsManager.Billing.Alert.limitationPressed(name: alertName)
                showTwoWeekProTrialEndedAlert = false
                hasClosedTrialEndedAlert = true
            },
            subscriptionText: "Continue with Pro!",
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
