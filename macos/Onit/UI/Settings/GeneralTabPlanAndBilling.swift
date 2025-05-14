//
//  GeneralTabPlanAndBilling.swift
//  Onit
//
//  Created by Loyd Kim on 4/30/25.
//

import Foundation
import SwiftUI

struct GeneralTabPlanAndBilling: View {
    @Environment(\.appState) var appState
    @Environment(\.openURL) var openURL
    
    @State private var planType: String? = nil
    @State private var chatGenerationsUsage: Int? = nil
    @State private var chatGenerationsQuota: Int? = nil
    @State private var renewalDate: String? = nil
    
    @State private var freeTrialAvailable: Bool?
    @State private var checkingFreeTrialAvailable: Bool = true
    
    @State private var fetchingSubscriptionData: Bool = false
    @State private var subscriptionDataErrorMessage: String = ""
    
    private var userLoggedIn: Bool {
        appState.account != nil
    }
    
    var body: some View {
        SettingsSection(
            iconText: "􀋃",
            title: "Plan and billing"
        ) {
            VStack(alignment: .leading, spacing: 11) {
                if !subscriptionDataErrorMessage.isEmpty {
                    Text(subscriptionDataErrorMessage)
                        .styleText(
                            size: 13,
                            weight: .regular,
                            color: .red
                        )
                }
                
                if fetchingSubscriptionData {
                    shimmers
                } else if userLoggedIn,
                   let planType = planType,
                   let usage = chatGenerationsUsage,
                   let quota = chatGenerationsQuota,
                   let renewalDate = renewalDate
                {
                    caption(
                        planType: planType,
                        usage: usage,
                        quota: quota,
                        renewalDate: renewalDate
                    )
                }
                
                if !userLoggedIn {
                    upgradeToProButton
                } else if appState.subscriptionStatus == SubscriptionStatus.free {
                    HStack(spacing: 11) {
                        if checkingFreeTrialAvailable {
                            Loader()
                        } else if let freeTrialAvailable {
                            if freeTrialAvailable {
                                startTwoWeekProTrialButton
                            } else {
                                upgradeToProButton
                            }
                        }
                        
                        if let _ = appState.subscription {
                            viewPastBillingInfoButton
                        }
                    }
                } else if appState.subscriptionStatus == SubscriptionStatus.trialing || appState.subscriptionStatus == SubscriptionStatus.active {
                    HStack(spacing: 11) {
                        if appState.subscriptionCanceled {
                            renewSubscriptionButton
                        }
                        
                        manageSubscriptionButton
                    }
                }
                
                if !userLoggedIn ||
                    appState.subscriptionCanceled ||
                    planType == SubscriptionStatus.free
                {
                    SubscriptionFeatures()
                }
            }
        }
        .task() {
            await fetchSubscriptionData()
        }
        .onChange(of: userLoggedIn) {
            if userLoggedIn {
                Task {
                    await fetchSubscriptionData()
                }
            }
        }
    }
}

// MARK: - Child Components

extension GeneralTabPlanAndBilling {
    private var upgradeToProButton: some View {
        SimpleButton(
            iconText: "🚀",
            text: "Upgrade to PRO",
            action: {
                Task {
                    if let error = await Stripe.openSubscriptionForm(openURL) {
                        subscriptionDataErrorMessage = error
                    }
                }
            },
            background: .blue
        )
    }
    
    private var startTwoWeekProTrialButton: some View {
        SimpleButton(
            iconText: "🚀",
            text: "Start 2-Week PRO Trial",
            action: {
                Task {
                    if let error = await Stripe.openSubscriptionForm(openURL) {
                        subscriptionDataErrorMessage = error
                    }
                }
            },
            background: .blue
        )
    }
    
    private var renewSubscriptionButton: some View {
        SimpleButton(
            iconText: "💫",
            text: "Renew Subscription",
            action: {
                Task {
                    await renewSubscription()
                }
            },
            background: .blue
        )
    }
    
    private var manageSubscriptionButton: some View {
        SimpleButton(
            iconText: "⚙️",
            text: "Manage Subscription",
            action: {
                Task { await openBillingPortal() }
            }
        )
    }
    
    private var viewPastBillingInfoButton: some View {
        SimpleButton(
            iconText: "⚙️",
            text: "View Past Billing Info",
            action: {
                Task { await openBillingPortal() }
            }
        )
    }
    
    private var shimmers: some View {
        VStack(alignment: .leading, spacing: 6) {
            Shimmer(width: 100, height: 16)
            Shimmer(width: 160, height: 16)
        }
    }
    
    private func captionText(_ text: String) -> some View {
        Text(text)
            .styleText(
                size: 13,
                weight: .regular,
                color: Color(hex: "#A1A4AF") ?? .gray100
            )
    }
    
    private func getCanceledText(_ renewalDate: String) -> String? {
        if let subscriptionCanceled = appState.subscription?.cancelAtPeriodEnd,
           subscriptionCanceled
        {
            return "Your Onit subscription expires on \(renewalDate)."
        } else {
            return nil
        }
    }
    
    private func handleRenewalDate(_ renewalDate: String) -> String {
        if planType == SubscriptionStatus.free {
            return "Free quota renews \(renewalDate)."
        } else if planType == SubscriptionStatus.active {
            if let canceledText = getCanceledText(renewalDate) {
                return canceledText
            } else {
                return "Next billing & renewal date is \(renewalDate)."
            }
        } else if planType == SubscriptionStatus.trialing {
            if let canceledText = getCanceledText(renewalDate) {
                return canceledText
            } else {
                return "Your trial ends \(renewalDate)."
            }
        } else {
            return "Renewal date not available."
        }
    }
    
    private func caption(
        planType: String,
        usage: Int,
        quota: Int,
        renewalDate: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(
                appState.subscriptionCanceled ? "Pro plan expiring soon" : planType
            ).styleText(size: 13, weight: .regular)
            
            VStack(alignment: .leading, spacing: 1) {
                if !appState.subscriptionCanceled {
                    if planType == SubscriptionStatus.active {
                        captionText("You are subscribed to the Onit Pro plan!")
                    } else if planType == SubscriptionStatus.trialing {
                        captionText("You are on the Pro free trial!")
                    }
                }
                
                captionText("\(usage)/\(quota) generations used.")
                
                captionText(handleRenewalDate(renewalDate))
            }
        }
    }
}

// MARK: - Private Functions

extension GeneralTabPlanAndBilling {
    private func fetchSubscriptionData() async {
        do {
            subscriptionDataErrorMessage = ""
            fetchingSubscriptionData = true
            
            if userLoggedIn {
                await refreshSubscriptionState()
                
                planType = appState.subscriptionStatus
                
                if appState.subscriptionStatus == SubscriptionStatus.free {
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
    
    private func openBillingPortal() async {
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
    
    private func refreshSubscriptionState() async {
        do {
            let client = FetchingClient()
            appState.subscription = try await client.getSubscription()
        } catch {
            subscriptionDataErrorMessage = error.localizedDescription
        }
    }
    
    private func renewSubscription() async {
        do {
            let client = FetchingClient()
            try await client.updateSubscriptionCancel(cancelAtPeriodEnd: false)
            await fetchSubscriptionData()
        } catch {
            subscriptionDataErrorMessage = error.localizedDescription
        }
    }
}
