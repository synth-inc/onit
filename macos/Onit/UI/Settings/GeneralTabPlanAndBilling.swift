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
                    manageSubscriptionButton
                } else if appState.subscriptionStatus == SubscriptionStatus.canceled {
                    HStack(spacing: 11) {
                        renewSubscriptionButton
                        manageSubscriptionButton
                    }
                }
                
                if !userLoggedIn ||
                    planType == SubscriptionStatus.free ||
                    planType == SubscriptionStatus.trialing
                {
                    SubscriptionFeatures()
                }
            }
        }
        .onAppear() {
            Task {
                await fetchSubscriptionData()
            }
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
    
    private func caption(
        planType: String,
        usage: Int,
        quota: Int,
        renewalDate: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(planType).styleText(size: 13, weight: .regular)
            
            VStack(alignment: .leading, spacing: 1) {
                if planType == SubscriptionStatus.active {
                    captionText("You are subscribed to the Onit Pro plan!")
                } else if planType == SubscriptionStatus.trialing {
                    captionText("You are on the Pro free trial!")
                }
                
                captionText("\(usage)/\(quota) generations used.")
                
                captionText(
                    planType == SubscriptionStatus.free ? "Free quota renews \(renewalDate)." :
                        planType == SubscriptionStatus.canceled ? "Your Onit subscription expires on \(renewalDate)." :
                        planType == SubscriptionStatus.active ? "Next billing & renewal date is \(renewalDate)." :
                        planType == SubscriptionStatus.trialing ? "Your trial ends \(renewalDate)." :
                        "Renewal date not available."
                )
            }
        }
    }
}

// MARK: - Private Functions

extension GeneralTabPlanAndBilling {
    private func fetchSubscriptionData() async -> Void {
        Task {
            do {
                subscriptionDataErrorMessage = ""
                fetchingSubscriptionData = true
                
                if userLoggedIn {
                    await refreshSubscriptionState()
                    
                    planType = appState.subscriptionStatus
                    
                    if appState.subscriptionStatus == SubscriptionStatus.free {
                        checkingFreeTrialAvailable = true
                        
                        let response = await Stripe.checkFreeTrialAvailable()
                        let trialAvailable = response.lowercased()
                        
                        if trialAvailable == "true" { freeTrialAvailable = true }
                        else if trialAvailable == "false" { freeTrialAvailable = false }
                        else { subscriptionDataErrorMessage = response }
                        
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
