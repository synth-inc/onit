//
//  AnalyticsManager+ContextPicker.swift
//  Onit
//
//  Created by Kévin Naudin on 21/05/2025.
//

import PostHog

extension AnalyticsManager {
    
    struct ContextPicker {
        static func uploadFilePressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("context_picker_upload_file", properties: properties)
        }
        
        static func autoContextPressed() {
            let properties = AnalyticsManager.getCommonProperties()
            
            PostHogSDK.shared.capture("context_picker_auto_context", properties: properties)
        }
    }
}
