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
            AnalyticsManager.sendCommonEvent(event: "context_picker_upload_file")
        }
        
        static func autoContextPressed() {
            AnalyticsManager.sendCommonEvent(event: "context_picker_auto_context")
        }
    }
}
