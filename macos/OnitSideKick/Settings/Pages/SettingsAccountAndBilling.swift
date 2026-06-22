//
//  SettingsAccountAndBilling.swift
//  Onit
//
//  Created by Loyd Kim on 9/2/25.
//

import Defaults
import SwiftUI

struct SettingsAccountAndBilling: View {
    // MARK: - Environment
    
    @Environment(\.appState) var appState
    @Environment(\.openURL) var openURL
    
    // MARK: - States
    
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var stripeManager = StripeManager.shared

    @Default(.settingsPage) private var settingsPage

    // MARK: - Private Variables
    
    private let modelProvidersManager = ModelProvidersManager.shared
    
    private var signInStatusText: String {
        if authManager.userLoggedIn {
            if let email = authManager.account?.email {
                return String(format: String.localized("You are signed in as %@", table: "Settings"), email)
            } else if let appleEmail = authManager.account?.appleEmail {
                return String(format: String.localized("You are signed in as %@", table: "Settings"), appleEmail)
            } else {
                return String.localized("Signed in.", table: "Settings")
            }
        } else {
            return String.localized("Create an account to save your settings and preferences.", table: "Settings")
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            accountSection
            billingSection
        }
    }
    
    // MARK: - Child Components: Shared
    
    private func captionText(_ text: String) -> some View {
        Text(text)
            .styleText(
                size: 13,
                weight: .regular,
                color: Color.S_1
            )
    }

    // MARK: - Child Components: Account Section
    
    private var accountSection: some View {
        SettingsPageSection(title: .init(text: String.localized("Account", table: "Settings"))) {
            SettingsPageSubsection(
                vertical: .init(spacing: 12),
                header: .init(title: signInStatusText)
            ) {
                accountAuthButtonsView
            }
        }
    }
    
    private var accountAuthButtonsView: some View {
        HStack(alignment: .center, spacing: 9) {
            if authManager.userLoggedIn {
                AuthHelpers.logoutButton
                    .cornerRadius(7)
                DeleteAccountButton()
                    .cornerRadius(7)
            } else {
                AuthHelpers.createAnAccountButton {
                    OnboardingWindowManager.shared.showAuthOnly()
                }
                .cornerRadius(7)
                AuthHelpers.signInButton {
                    OnboardingWindowManager.shared.showAuthOnly()
                }
                .cornerRadius(7)
            }
        }
    }
    
    // MARK: - Child Components: Billing Section
    
    private var billingSection: some View {
        SettingsPageSection(title: .init(text: String.localized("Plan & Billing", table: "Settings"))) {
            SettingsPageSubsection(vertical: .init(spacing: 12)) {
                planAndBillingSubscriptionErrorView
                planAndBillingInfo
                subscriptionActions

                if !authManager.userLoggedIn ||
                    appState.subscriptionCanceled ||
                    stripeManager.planType == SubscriptionStatus.free
                {
                    SubscriptionFeatures()
                }
            }
        }
        .task() {
            await stripeManager.fetchSubscriptionData()
        }
        .onChange(of: authManager.userLoggedIn) { _, userLoggedIn in
            if userLoggedIn {
                Task {
                    await stripeManager.fetchSubscriptionData()
                }
            }
        }
    }
    
    // MARK: - Child Components: Plan & Billing
    
    @ViewBuilder
    private var planAndBillingSubscriptionErrorView: some View {
        if let subscriptionDataErrorMessage = stripeManager.subscriptionDataErrorMessage {
            Text(subscriptionDataErrorMessage)
                .styleText(
                    size: 13,
                    weight: .regular,
                    color: Color.red500
                )
        }
    }
    
    private var planAndBillingFetchingSubscriptionDataShimmers: some View {
        VStack(alignment: .leading, spacing: 6) {
            Shimmer(width: 100, height: 16)
            Shimmer(width: 160, height: 16)
        }
    }
    
    // MARK: - Child Components: Plan & Billing → Info
    
    @ViewBuilder
    private var planAndBillingInfo: some View {
        if stripeManager.fetchingSubscriptionData {
            planAndBillingFetchingSubscriptionDataShimmers
        } else if authManager.userLoggedIn,
                  let planType = stripeManager.planType,
                  let usage = stripeManager.chatGenerationsUsage,
                  let quota = stripeManager.chatGenerationsQuota,
                  let renewalDate = stripeManager.renewalDate
        {
            planAndBillingCaption(
                planType: planType,
                usage: usage,
                quota: quota,
                renewalDate: renewalDate
            )
        }
    }
    
    private func planAndBillingCaption(
        planType: String,
        usage: Int,
        quota: Int,
        renewalDate: String
    ) -> some View {
        let isOnFreePlan = planType == SubscriptionStatus.free
        
        let isOnActivePlan =
            planType == SubscriptionStatus.active ||
            planType == SubscriptionStatus.trialing
        
        return VStack(alignment: .leading, spacing: 8) {
            Text(
                appState.subscriptionCanceled ? String.localized("Pro plan expiring soon", table: "Settings") : SubscriptionStatus.localizedName(planType)
            )
            .styleText(
                size: 13,
                weight: .regular
            )

            VStack(alignment: .leading, spacing: 1) {
                if !appState.subscriptionCanceled {
                    if planType == SubscriptionStatus.active {
                        captionText(String.localized("You are subscribed to the Onit Pro plan!", table: "Settings"))
                    } else if planType == SubscriptionStatus.trialing {
                        captionText(String.localized("You are subscribed to the Onit Pro 2-Week Trial!", table: "Settings"))
                    }
                }

                captionText(
                    generationsUsedText(usage: usage, quota: quota, isOnFreePlan: isOnFreePlan, isOnActivePlan: isOnActivePlan)
                )

                if modelProvidersManager.userHasRemoteAPITokens {
                    captionText(
                        String.localized("Prompts sent using your own API tokens do not count against your free quota.", table: "Settings")
                    )
                }

                captionText(
                    handleRenewalDate(renewalDate)
                )
            }
        }
    }
    
    // MARK: - Child Components: Plan & Billing → Subscription Actions
    
    private var planAndBillingFreeTrialActions: some View {
        HStack(spacing: 8) {
            if stripeManager.checkingFreeTrialAvailable {
                Loader()
            } else if stripeManager.freeTrialAvailable != nil {
                if stripeManager.freeTrialAvailable! {
                    planAndBillingStartTwoWeekProTrialButton
                } else {
                    planAndBillingUpgradeToProButton
                }
            }
            
            if appState.subscription != nil {
                planAndBillingViewPastBillingInfoButton
            }
        }
    }
    
    private var planAndBillingActiveSubscriptionActions: some View {
        HStack(spacing: 11) {
            if appState.subscriptionCanceled {
                planAndBillingRenewSubscriptionButton
            }
            
            planAndBillingManageSubscriptionButton
        }
    }
    
    @ViewBuilder
    private var subscriptionActions: some View {
        if !authManager.userLoggedIn {
            planAndBillingUpgradeToProButton
        } else if appState.subscriptionStatus == SubscriptionStatus.free {
            planAndBillingFreeTrialActions
        } else if appState.subscriptionStatus == SubscriptionStatus.trialing || appState.subscriptionStatus == SubscriptionStatus.active {
            planAndBillingActiveSubscriptionActions
        }
    }
    
    // MARK: - Child Components: Plan & Billing → Plan Buttons
    
    private var planAndBillingUpgradeToProButton: some View {
        SimpleButton(
            iconText: "🚀",
            text: String.localized("Upgrade to PRO", table: "Settings"),
            textColor: Color.white,
            cornerRadius: 7,
            action: {
                AnalyticsManager.Billing.upgradeProPressed()
                Task {
                    if let error = await Stripe.openSubscriptionForm(openURL) {
                        stripeManager.setSubscriptionDataErrorMessage(error)
                    }
                }
            },
            background: Color.blue
        )
    }

    private var planAndBillingStartTwoWeekProTrialButton: some View {
        SimpleButton(
            iconText: "🚀",
            text: String.localized("Start 2-Week PRO Trial", table: "Settings"),
            textColor: Color.white,
            cornerRadius: 7,
            action: {
                AnalyticsManager.Billing.startFreeTrialPressed()
                Task {
                    if let error = await Stripe.openSubscriptionForm(openURL) {
                        stripeManager.setSubscriptionDataErrorMessage(error)
                    }
                }
            },
            background: Color.blue
        )
    }

    private var planAndBillingRenewSubscriptionButton: some View {
        SimpleButton(
            iconText: "💫",
            text: String.localized("Renew Subscription", table: "Settings"),
            textColor: Color.white,
            cornerRadius: 7,
            action: {
                AnalyticsManager.Billing.renewSubscriptionPressed()
                Task {
                    await stripeManager.renewSubscription()
                }
            },
            background: Color.blue
        )
    }

    private var planAndBillingManageSubscriptionButton: some View {
        SimpleButton(
            iconText: "⚙️",
            text: String.localized("Manage Subscription", table: "Settings"),
            cornerRadius: 7,
            action: {
                AnalyticsManager.Billing.manageSubscriptionPressed()
                Task {
                    await stripeManager.openBillingPortal(with: openURL)
                }
            }
        )
    }

    private var planAndBillingViewPastBillingInfoButton: some View {
        SimpleButton(
            iconText: "⚙️",
            text: String.localized("View Past Billing Info", table: "Settings"),
            cornerRadius: 7,
            action: {
                AnalyticsManager.Billing.viewPastBillingsPressed()
                Task {
                    await stripeManager.openBillingPortal(with: openURL)
                }
            }
        )
    }
    
    // MARK: - Private Functions: Plan & Billing
    
    private func getCanceledText(_ renewalDate: String) -> String? {
        if let subscriptionCanceled = appState.subscription?.cancelAtPeriodEnd,
           subscriptionCanceled
        {
            return String(format: String.localized("Your Onit subscription expires on %@.", table: "Settings"), renewalDate)
        } else {
            return nil
        }
    }

    private func handleRenewalDate(_ renewalDate: String) -> String {
        switch stripeManager.planType {

        case SubscriptionStatus.free:
            return String(format: String.localized("Free quota renews %@.", table: "Settings"), renewalDate)

        case SubscriptionStatus.active:
            if let canceledText = getCanceledText(renewalDate) {
                return canceledText
            } else {
                return String(format: String.localized("Next billing & renewal date is %@.", table: "Settings"), renewalDate)
            }

        case SubscriptionStatus.trialing:
            if let canceledText = getCanceledText(renewalDate) {
                return canceledText
            } else {
                return String(format: String.localized("Your trial ends %@.", table: "Settings"), renewalDate)
            }

        default:
            return String.localized("Renewal date not available.", table: "Settings")
        }
    }
    
    private func generationsUsedText(
        usage: Int,
        quota: Int,
        isOnFreePlan: Bool,
        isOnActivePlan: Bool
    ) -> String {
        let baseText: String
        if isOnFreePlan {
            baseText = String(format: String.localized("%d/%d Free generations used", table: "Settings"), usage, quota)
        } else {
            baseText = String(format: String.localized("%d/%d generations used", table: "Settings"), usage, quota)
        }

        if isOnActivePlan {
            return baseText + " " + String.localized("(more available upon request)", table: "Settings")
        } else {
            return baseText
        }
    }
}
