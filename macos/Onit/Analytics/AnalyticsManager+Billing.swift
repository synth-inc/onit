//
//  AnalyticsManager+Billing.swift
//  Onit
//
//  Created by Kévin Naudin on 21/05/2025.
//

import PostHog

extension AnalyticsManager {
    
    struct Billing {
        static func startFreeTrialPressed() {
            AnalyticsManager.sendCommonEvent(event: "billing_start_free_trial")
        }
        
        static func upgradeProPressed() {
            AnalyticsManager.sendCommonEvent(event: "billing_upgrade_pro")
        }
        
        static func renewSubscriptionPressed() {
            AnalyticsManager.sendCommonEvent(event: "billing_renew_subscription")
        }
        
        static func manageSubscriptionPressed() {
            AnalyticsManager.sendCommonEvent(event: "billing_manage_subscription")
        }
        
        static func viewPastBillingsPressed() {
            AnalyticsManager.sendCommonEvent(event: "billing_view_past_billings")
        }
    }
}
