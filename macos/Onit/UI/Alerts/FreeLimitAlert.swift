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
    private var errorMessageFallback: String = "Could not retrieve renewal date."
    
    private var footerSupportingText: String {
        if !errorMessage.isEmpty {
            return errorMessage
        } else if fetchingRenewalDate {
            return "Retrieving renewal date."
        } else if let renewalDate = renewalDate {
            return "Next renewal: \(renewalDate)"
        } else {
            return errorMessageFallback
        }
    }
    
    var body: some View {
        SubscriptionAlert(
            title: "Free Limit Reached",
            close: {
                AnalyticsManager.Billing.Alert.closed(name: alertName)
                appState?.showFreeLimitAlert = false
            },
            description: "You have used your free requests for this month.",
            subscriptionText: "Upgrade to Pro!",
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
