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
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("toolbar_escape", properties: properties)
        }
        
        static func newChatPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("toolbar_new_chat", properties: properties)
        }
        
        static func systemPromptPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("toolbar_system_prompt", properties: properties)
        }
        
        static func llmModeToggled(oldValue: String, newValue: String) {
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
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("toolbar_settings", properties: properties)
        }
    }
}
