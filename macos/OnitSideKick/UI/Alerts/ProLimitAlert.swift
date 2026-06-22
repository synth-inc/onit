//
//  ProLimitAlert.swift
//  Onit
//
//  Created by Loyd Kim on 5/2/25.
//

import SwiftUI

struct ProLimitAlert: View {
    @Environment(\.appState) var appState
    
    @State private var fetchingData: Bool = true
    @State private var chatRequestsQuota: Int? = nil
    @State private var renewalDate: String? = nil
    @State private var quotaErrorMessage: String = ""
    @State private var renewalDateErrorMessage: String = ""
    
    private let alertName = "pro_limit"
    private var quotaErrorMessageFallback: String = String.localized("Could not retrieve max requests quota.", table: "Sidekick")
    private var renewalErrorMessageFallback: String = String.localized("Could not retrieve renewal date.", table: "Sidekick")

    private var description: String {
        if !quotaErrorMessage.isEmpty {
            return quotaErrorMessage
        } else if let quota = chatRequestsQuota {
            return String.localized("You have used your %d requests for this month.\nYour next renewal is:", table: "Sidekick", quota)
        } else {
            return quotaErrorMessageFallback
        }
    }

    private var caption: String {
        if !renewalDateErrorMessage.isEmpty {
            return renewalDateErrorMessage
        } else if let renewalDate = renewalDate {
            return "💫 \(renewalDate)"
        } else {
            return renewalErrorMessageFallback
        }
    }
    
    var body: some View {
        SubscriptionAlert(
            title: String.localized("Pro Limit Reached", table: "Sidekick"),
            close: {
                AnalyticsManager.Billing.Alert.closed(name: alertName)
                appState.showProLimitAlert = false
            },
            description: description,
            descriptionLoading: fetchingData,
            caption: caption
        )
        .onAppear {
            AnalyticsManager.Billing.Alert.opened(name: alertName)
        }
        .task {
            await fetchData()
        }
    }
}

// MARK: - Private Functions

extension ProLimitAlert {
    private func fetchData() async {
        do {
            fetchingData = true
            
            let client = FetchingClient()
            let chatUsageResponse = try await client.getChatUsage()
            
            if let quota = chatUsageResponse?.quota {
                chatRequestsQuota = Int(quota.rounded())
            } else {
                quotaErrorMessage = quotaErrorMessageFallback
            }
            
            if let currentPeriodEnd = chatUsageResponse?.currentPeriodEnd {
                renewalDate = convertEpochDateToCleanDate(
                    epochDate: currentPeriodEnd
                )
            } else {
                renewalDateErrorMessage = renewalErrorMessageFallback
            }
            
            fetchingData = false
        } catch {
            quotaErrorMessage = quotaErrorMessageFallback
            renewalDateErrorMessage = renewalErrorMessageFallback
            fetchingData = false
        }
    }
}
