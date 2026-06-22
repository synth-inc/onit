//
//  AnalyticsManager+Panel.swift
//  Onit
//
//  Created by Kévin Naudin on 21/05/2025.
//

import AppKit
import PostHog

extension AnalyticsManager {
    
    struct Panel {
        static func opened(displayMode: String, appName: String? = nil) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["display_mode"] = displayMode
            if let appName = appName {
                properties["app_name"] = appName
            }
            
            PostHogSDK.shared.capture("panel_opened", properties: properties)
        }
        
        static func closed(displayMode: String, appName: String? = nil) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["display_mode"] = displayMode
            if let appName = appName {
                properties["app_name"] = appName
            }
            
            PostHogSDK.shared.capture("panel_closed", properties: properties)
        }
        
        static func resized(oldWidth: CGFloat, newWidth: CGFloat) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["old_width"] = oldWidth
            properties["new_width"] = newWidth
            
            PostHogSDK.shared.capture("panel_resized", properties: properties)
        }
    }
    
    // TODO: KNA - Should be moved somewhere else
    static func shortcutPressed(for shortcutName: String, panelOpened: Bool) {
        var properties = Self.getCommonProperties()
        
        properties["shortcut_name"] = shortcutName
        properties["panel_opened"] = panelOpened
        
        PostHogSDK.shared.capture("shortcut_pressed", properties: properties)
    }
}
