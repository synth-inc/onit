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
        
        struct Alert {
            static func opened(name: String) {
                var properties = AnalyticsManager.getCommonProperties()
                
                properties["alert_name"] = name
                
                PostHogSDK.shared.capture("billing_alert_opened", properties: properties)
            }
            
            static func closed(name: String) {
                var properties = AnalyticsManager.getCommonProperties()
                
                properties["alert_name"] = name
                
                PostHogSDK.shared.capture("billing_alert_closed", properties: properties)
            }
            
            static func limitationPressed(name: String) {
                var properties = AnalyticsManager.getCommonProperties()
                
                properties["alert_name"] = name
                
                PostHogSDK.shared.capture("billing_alert_limitation", properties: properties)
            }
            
            static func subscriptionPressed(name: String) {
                var properties = AnalyticsManager.getCommonProperties()
                
                properties["alert_name"] = name
                
                PostHogSDK.shared.capture("billing_alert_subscription", properties: properties)
            }
        }
    }
}
