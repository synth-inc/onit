//
//  AnalyticsManager+ModelPicker.swift
//  Onit
//
//  Created by Kévin Naudin on 21/05/2025.
//

import PostHog

extension AnalyticsManager {
    
    struct ModelPicker {
        
        static func opened() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("model_picker_opened", properties: properties)
        }
        
        static func settingsPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("model_picker_settings", properties: properties)
        }
        
        static func modelSelected(local: Bool, model: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["llm_mode"] = local ? "local" : "remote"
            properties["llm_model"] = model
            
            PostHogSDK.shared.capture("model_picker_selected", properties: properties)
        }
        
        static func localSetupPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("model_picker_local_setup", properties: properties)
        }
    }
}
