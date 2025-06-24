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
            AnalyticsManager.sendCommonEvent(event: "chat_paperclip")
        }
        
        static func addContextPressed() {
            AnalyticsManager.sendCommonEvent(event: "chat_add_context")
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
        
        static func webSearchToggled(oldValue: Bool, newValue: Bool) {
            var properties = AnalyticsManager.getCommonProperties()
            
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
