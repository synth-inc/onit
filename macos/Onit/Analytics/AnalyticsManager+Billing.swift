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
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("billing_start_free_trial", properties: properties)
        }
        
        static func upgradeProPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("billing_upgrade_pro", properties: properties)
        }
        
        static func renewSubscriptionPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("billing_renew_subscription", properties: properties)
        }
        
        static func manageSubscriptionPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("billing_manage_subscription", properties: properties)
        }
        
        static func viewPastBillingsPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("billing_view_past_billings", properties: properties)
        }
    }
}
