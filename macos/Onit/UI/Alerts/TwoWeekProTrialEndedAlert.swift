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
    
    var body: some View {
        SubscriptionAlert(
            title: "Your 2-week Pro trial has ended",
            description: "Downgrade to free plan →",
            descriptionAction: {
                showTwoWeekProTrialEndedAlert = false
                hasClosedTrialEndedAlert = true
            },
            subscriptionText: "Continue with Pro!",
            showSubscriptionPerks: true
        )
    }
}
