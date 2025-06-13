//
//  AnalyticsManager+Debug.swift
//  Onit
//
//  Created by Kévin Naudin on 09/06/2025.
//

import PostHog

extension AnalyticsManager {
    
    static func ocrComparisonFailed(appName: String, matchPercentage: Int) {
        var properties = Self.getCommonProperties()
        properties["app_name"] = appName
        properties["match_percentage"] = matchPercentage
        
        PostHogSDK.shared.capture("ocr_comparison_failed", properties: properties)
    }
    
    static func ocrComparisonCompleted(appName: String, matchPercentage: Int) {
        var properties = Self.getCommonProperties()
        properties["app_name"] = appName
        properties["match_percentage"] = matchPercentage
        
        PostHogSDK.shared.capture("ocr_comparison_completed", properties: properties)
    }
}