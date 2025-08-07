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
            
            PostHogSDK.shared.capture("settings_tab_selected", properties: properties)
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
        
        // MARK: - Models Settings
        
        struct Models {
            static func remoteModelAdded(_ remoteModel: AIModel) {
                var properties = AnalyticsManager.getCommonProperties()
                
                properties["remote_model_id"] = remoteModel.id
                properties["remote_model_display_name"] = remoteModel.displayName
                properties["remote_model_provider"] = remoteModel.provider.title
                
                PostHogSDK.shared.capture("remote_model_added", properties: properties)
            }
        }
    }
}
