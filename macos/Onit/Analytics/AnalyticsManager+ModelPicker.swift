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
            AnalyticsManager.sendCommonEvent(event: "model_picker_opened")
        }
        
        static func settingsPressed() {
            AnalyticsManager.sendCommonEvent(event: "model_picker_settings")
        }
        
        static func modelSelected(local: Bool, model: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["llm_mode"] = local ? "local" : "remote"
            properties["llm_model"] = model
            
            PostHogSDK.shared.capture("model_picker_selected", properties: properties)
        }
        
        static func localSetupPressed() {
            AnalyticsManager.sendCommonEvent(event: "model_picker_local_setup")
        }
    }
}
