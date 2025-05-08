//
//  TwoWeekProTrialEndedAlert.swift
//  Onit
//
//  Created by Loyd Kim on 5/2/25.
//

import SwiftUI

struct TwoWeekProTrialEndedAlert: View {
    @Environment(\.appState) var appState
    
    @State var descriptionActionLoading: Bool = false
    @State var errorMessage: String = ""
    
    var body: some View {
        SubscriptionAlert(
            title: "Your 2-week Pro trial has ended",
            description: "Downgrade to free plan →",
            descriptionAction: {
                Task {
                    await downgradeToFreePlan()
                }
            },
            descriptionActionLoading: descriptionActionLoading,
            subscriptionText: "Continue with Pro!",
            showSubscriptionPerks: true,
            errorMessage: $errorMessage
        )
    }
}

// MARK: - Private Functions

extension TwoWeekProTrialEndedAlert {
    private func refreshSubscriptionState() async {
        do {
            let client = FetchingClient()
            appState.subscription = try await client.getSubscription()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func downgradeToFreePlan() async {
        do {
            descriptionActionLoading = true
            
            let client = FetchingClient()
            try await client.updateSubscriptionCancel(cancelAtPeriodEnd: true)
            await refreshSubscriptionState()
            
            descriptionActionLoading = false
        } catch {
            errorMessage = error.localizedDescription
            descriptionActionLoading = false
        }
    }
}
