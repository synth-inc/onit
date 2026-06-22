//
//  AnalyticsManager+Auth.swift
//  Onit
//
//  Created by Kévin Naudin on 22/05/2025.
//

import PostHog

extension AnalyticsManager {
    struct Auth {
        static func opened() {
            AnalyticsManager.sendCommonEvent(event: "auth_opened")
        }
        
        static func pressed(provider: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["provider"] = provider
            
            PostHogSDK.shared.capture("auth_pressed", properties: properties)
        }
        
        static func requested(provider: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["provider"] = provider
            
            PostHogSDK.shared.capture("auth_requested", properties: properties)
        }
        
        static func cancelled(provider: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["provider"] = provider
            
            PostHogSDK.shared.capture("auth_cancelled", properties: properties)
        }
        
        static func error(provider: String, error: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["provider"] = provider
            properties["error"] = error
            
            PostHogSDK.shared.capture("auth_error", properties: properties)
        }
        
        static func success(provider: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["provider"] = provider
            
            PostHogSDK.shared.capture("auth_login_success", properties: properties)
        }
        
        static func failed(provider: String, error: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["provider"] = provider
            properties["error"] = error
            
            PostHogSDK.shared.capture("auth_login_failed", properties: properties)
        }
    }
}
