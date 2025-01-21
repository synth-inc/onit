//
//  PostHogFeatureFlagManager.swift
//  Onit
//
//  Created by Kévin Naudin on 21/01/2025.
//

import PostHog
import Foundation

/**
 * PostHog implementation of the `FeatureFlagManagerLogic`
 */
final class PostHogFeatureFlagManager: FeatureFlagManagerLogic, Sendable {
    
    // MARK: - Singleton instance
    
    static let shared = PostHogFeatureFlagManager()
    
    // MARK: - FeatureFlagManagerLogic
    
    /** See ``FeatureFlagManagerLogic`` protocol */
    func configure() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "PostHogApiKey") as? String,
              let host = Bundle.main.object(forInfoDictionaryKey: "PostHogHost") as? String else {
            print("PostHog -> Error not initialized due to missing API key or host")
            return
        }
        
        let config = PostHogConfig(apiKey: apiKey, host: host)
        
        PostHogSDK.shared.setup(config)
    }
    
    func reload() {
        PostHogSDK.shared.reloadFeatureFlags()
    }
    
    func isAccessibilityEnabled() -> Bool {
        return PostHogSDK.shared.isFeatureEnabled("accessibility")
    }
}
