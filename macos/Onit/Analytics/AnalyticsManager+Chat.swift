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
    }
}
