//
//  AnalyticsManager+Debug.swift
//  Onit
//
//  Created by Kévin Naudin on 09/06/2025.
//

import PostHog

extension AnalyticsManager {
    struct Debug {
        static func ocrComparisonFailed(appName: String, matchPercentage: Int, documentRootDomain: String? = nil) {
            var properties = AnalyticsManager.getCommonProperties()
            properties["app_name"] = appName
            properties["match_percentage"] = matchPercentage
            
            if let domain = documentRootDomain {
                properties["document_domain"] = domain
            }
            
            PostHogSDK.shared.capture("ocr_comparison_failed", properties: properties)
        }
        
        static func ocrComparisonCompleted(appName: String, matchPercentage: Int, documentRootDomain: String? = nil) {
            var properties = AnalyticsManager.getCommonProperties()
            properties["app_name"] = appName
            properties["match_percentage"] = matchPercentage
            
            if let domain = documentRootDomain {
                properties["document_domain"] = domain
            }
            
            PostHogSDK.shared.capture("ocr_comparison_completed", properties: properties)
        }
    }
}
