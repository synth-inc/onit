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
    
    private var quotaErrorMessageFallback: String = "Could not retrieve max requests quota."
    private var renewalErrorMessageFallback: String = "Could not retrieve renewal date."
    
    private var description: String {
        if !quotaErrorMessage.isEmpty {
            return quotaErrorMessage
        } else if let quota = chatRequestsQuota {
            return "You have used your \(quota) requests for this month.\nYour next renewal is:"
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
            title: "Pro Limit Reached",
            close: { appState.showProLimitAlert = false },
            description: description,
            descriptionLoading: fetchingData,
            caption: caption
        )
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
