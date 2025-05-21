//
//  AnalyticsManager+Account.swift
//  Onit
//
//  Created by Kévin Naudin on 21/05/2025.
//

import PostHog

extension AnalyticsManager {
    struct Account {
        static func createAccountPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("account_create", properties: properties)
        }
        
        static func signInPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("account_sign_in", properties: properties)
        }
        
        static func logoutPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("account_logout", properties: properties)
        }
        
        static func deletePressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("account_delete", properties: properties)
        }
        
        static func deleteConfirmationCancelPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("account_delete_confirmation_cancel", properties: properties)
        }
        
        static func deleteConfirmationDeletePressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("account_delete_confirmation_delete", properties: properties)
        }
    }
}
