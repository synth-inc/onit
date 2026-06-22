//
//  FreeLimitAlert.swift
//  Onit
//
//  Created by Loyd Kim on 5/2/25.
//

import SwiftUI

struct FreeLimitAlert: View {
    @Environment(\.appState) var appState
    
    @State private var fetchingRenewalDate: Bool = true
    @State private var renewalDate: String? = nil
    @State private var errorMessage: String = ""
    
    private let alertName = "free_limit"
    private var errorMessageFallback: String = String.localized("Could not retrieve renewal date.", table: "Sidekick")

    private var footerSupportingText: String {
        if !errorMessage.isEmpty {
            return errorMessage
        } else if fetchingRenewalDate {
            return String.localized("Retrieving renewal date.", table: "Sidekick")
        } else if let renewalDate = renewalDate {
            return String.localized("Next renewal: %@", table: "Sidekick", renewalDate)
        } else {
            return errorMessageFallback
        }
    }
    
    var body: some View {
        SubscriptionAlert(
            title: String.localized("Free Limit Reached", table: "Sidekick"),
            close: {
                AnalyticsManager.Billing.Alert.closed(name: alertName)
                appState.showFreeLimitAlert = false
            },
            description: String.localized("You have used your free requests for this month.", table: "Sidekick"),
            subscriptionText: String.localized("Upgrade to Pro!", table: "Sidekick"),
            subscriptionAction: {
                AnalyticsManager.Billing.Alert.subscriptionPressed(name: alertName)
            },
            showSubscriptionPerks: true,
            footerSupportingText: footerSupportingText
        )
        .onAppear {
            AnalyticsManager.Billing.Alert.opened(name: alertName)
        }
        .task {
            await fetchRenewalDate()
        }
    }
}

// MARK: - Private Functions

extension FreeLimitAlert {
    private func fetchRenewalDate() async {
        fetchingRenewalDate = true
        
        do {
            let client = FetchingClient()
            let chatUsageResponse = try await client.getChatUsage()
            
            if let currentPeriodEnd = chatUsageResponse?.currentPeriodEnd {
                renewalDate = convertEpochDateToCleanDate(
                    epochDate: currentPeriodEnd
                )
            } else {
                errorMessage = errorMessageFallback
            }
            
            fetchingRenewalDate = false
        } catch {
            errorMessage = error.localizedDescription
            fetchingRenewalDate = false
        }
    }
}
