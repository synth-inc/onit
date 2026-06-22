//
//  AnalyticsManager+Technical.swift
//  Onit
//
//  Created by Kévin Naudin on 12/06/2025.
//

import PostHog

extension AnalyticsManager {
    struct Technical {
        static func defaultWindowState(source: String) {
            var properties = AnalyticsManager.getCommonProperties()
            
            properties["source"] = source
            
            PostHogSDK.shared.capture("technical_default_window_state", properties: properties)
            log.warning("Using default windowState from \(source)")
        }
    }
}
