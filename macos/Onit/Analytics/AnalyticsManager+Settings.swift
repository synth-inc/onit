//
//  AnalyticsManager+Settings.swift
//  Onit
//
//  Created by Kévin Naudin on 21/05/2025.
//

import PostHog

extension AnalyticsManager {
    
    struct Settings {
        static func opened(on tabName: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["tab_name"] = tabName
            
            PostHogSDK.shared.capture("settings_opened", properties: properties)
        }
        
        static func tabPressed(tabName: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["tab_name"] = tabName
            
            PostHogSDK.shared.capture("settings_tab", properties: properties)
        }
        
        // MARK: - General settings
        
        struct General {
            static func displayModePressed(oldValue: String, newValue: String) {
                var properties = AnalyticsManager.getCommonProperties()
                
                properties["old_value"] = oldValue
                properties["new_value"] = newValue
                
                PostHogSDK.shared.capture("settings_general_display_mode", properties: properties)
            }
        }
    }
}
