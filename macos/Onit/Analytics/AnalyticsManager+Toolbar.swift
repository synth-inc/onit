//
//  AnalyticsManager+Toolbar.swift
//  Onit
//
//  Created by Kévin Naudin on 21/05/2025.
//

import PostHog

extension AnalyticsManager {
    
    struct Toolbar {
        static func escapePressed() {
            AnalyticsManager.sendCommonEvent(event: "toolbar_escape")
        }
        
        static func newChatPressed() {
            AnalyticsManager.sendCommonEvent(event: "toolbar_new_chat")
        }
        
        static func systemPromptPressed() {
            AnalyticsManager.sendCommonEvent(event: "toolbar_system_prompt")
        }
        
        static func llmModeToggled(oldValue: InferenceMode, newValue: InferenceMode) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["old_value"] = oldValue
            properties["new_value"] = newValue
            
            PostHogSDK.shared.capture("toolbar_llm_mode", properties: properties)
        }
        
        static func historyPressed(displayed: Bool) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["history_displayed"] = displayed
            
            PostHogSDK.shared.capture("toolbar_history", properties: properties)
        }
        
        static func settingsPressed() {
            AnalyticsManager.sendCommonEvent(event: "toolbar_settings")
        }
    }
}
