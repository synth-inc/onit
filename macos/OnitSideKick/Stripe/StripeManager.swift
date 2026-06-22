//
//  StripeManager.swift
//  Onit
//
//  Created by Loyd Kim on 11/26/25.
//

import Foundation
import SwiftUI

@MainActor
final class StripeManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = StripeManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var planType: String? = nil
    @Published private(set) var chatGenerationsUsage: Int? = nil
    @Published private(set) var chatGenerationsQuota: Int? = nil
    @Published private(set) var renewalDate: String? = nil
    
    @Published private(set) var freeTrialAvailable: Bool? = nil
    @Published private(set) var checkingFreeTrialAvailable: Bool = true
    
    @Published private(set) var fetchingSubscriptionData: Bool = false
    @Published private(set) var subscriptionDataErrorMessage: String? = nil
    
    // MARK: - Public Functions: Published Setters
    
    func setSubscriptionDataErrorMessage(_ errorMessage: String?) {
        self.subscriptionDataErrorMessage = errorMessage
    }
    
    // MARK: - Public Functions: Fetching Client
    
    func fetchSubscriptionData() async {
        do {
            subscriptionDataErrorMessage = nil
            fetchingSubscriptionData = true
            
            if AuthManager.shared.userLoggedIn {
                await refreshSubscriptionState()
                
                planType = AppState.shared.subscriptionStatus
                
                if AppState.shared.subscriptionStatus == SubscriptionStatus.free {
                    checkingFreeTrialAvailable = true
                    
                    let (isFreeTrialAvailable, errorMessage) = await Stripe.checkFreeTrialAvailable()
                    
                    if let error = errorMessage {
                        subscriptionDataErrorMessage = error
                    } else if let isAvailable = isFreeTrialAvailable {
                        freeTrialAvailable = isAvailable
                    } else {
                        freeTrialAvailable = false
                    }
                    
                    checkingFreeTrialAvailable = false
                }
                
                
                // Setting chat usage and quota.
                let client = FetchingClient()
                let chatUsageResponse = try await client.getChatUsage()
                
                if let usage = chatUsageResponse?.usage {
                    chatGenerationsUsage = Int(usage.rounded())
                }
                if let quota = chatUsageResponse?.quota {
                    chatGenerationsQuota = Int(quota.rounded())
                }
                
                // Setting renewal date.
                if let currentPeriodEnd = chatUsageResponse?.currentPeriodEnd {
                    renewalDate = convertEpochDateToCleanDate(
                        epochDate: currentPeriodEnd
                    )
                }
            }
                
            fetchingSubscriptionData = false
        } catch {
            planType = nil
            chatGenerationsUsage = nil
            chatGenerationsQuota = nil
            renewalDate = nil
            
            subscriptionDataErrorMessage = error.localizedDescription
            
            fetchingSubscriptionData = false
        }
    }
    
    func openBillingPortal(with openURL: OpenURLAction) async {
        do {
            let client = FetchingClient()
            let response = try await client.createSubscriptionBillingPortalSession()
            if let url = URL(string: response.sessionUrl) {
                openURL(url)
            }
        } catch {
            subscriptionDataErrorMessage = error.localizedDescription
        }
    }
    
    func refreshSubscriptionState() async {
        do {
            let client = FetchingClient()
            AppState.shared.subscription = try await client.getSubscription()
        } catch {
            subscriptionDataErrorMessage = error.localizedDescription
        }
    }
    
    func renewSubscription() async {
        do {
            let client = FetchingClient()
            try await client.updateSubscriptionCancel(cancelAtPeriodEnd: false)
            await fetchSubscriptionData()
        } catch {
            subscriptionDataErrorMessage = error.localizedDescription
        }
    }
}
