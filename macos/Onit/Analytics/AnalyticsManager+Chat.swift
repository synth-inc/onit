//
//  AnalyticsManager+Chat.swift
//  Onit
//
//  Created by Kévin Naudin on 21/05/2025.
//

import Defaults
import PostHog

extension AnalyticsManager {
    
    struct Chat {
        
        static func paperclipPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("chat_paperclip", properties: properties)
        }
        
        static func addContextPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("chat_add_context", properties: properties)
        }
        
        /**
         * Track an event when user prompted
         * - parameter prompt: The current prompt
         */
        static func prompted(prompt: Prompt) {
            var properties = AnalyticsManager.getCommonProperties()
            var modelName = ""

            if Defaults[.mode] == .remote {
                if let model = Defaults[.remoteModel] {
                    if let customProviderName = model.customProviderName {
                        modelName = "\(customProviderName)/\(model.displayName)"
                    } else {
                        modelName = model.displayName
                    }
                }
            } else {
                modelName = Defaults[.localModel] ?? ""
            }
            
            properties["prompt_mode"] = Defaults[.mode].rawValue
            properties["prompt_model"] = modelName
            
            PostHogSDK.shared.capture("chat_prompted", properties: properties)
        }
        
        static func modelPressed(currentModel: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["current_model"] = currentModel
            
            PostHogSDK.shared.capture("chat_model_pressed", properties: properties)
        }
        
        static func webSearchToggled(isAvailable: Bool, oldValue: Bool, newValue: Bool) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["web_search_available"] = isAvailable
            properties["old_value"] = oldValue
            properties["new_value"] = newValue
            
            PostHogSDK.shared.capture("chat_web_search_toggled", properties: properties)
        }
        
        static func voicePressed(isAvailable: Bool) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["voice_available"] = isAvailable
            
            PostHogSDK.shared.capture("chat_voice_pressed", properties: properties)
        }
    }
}
