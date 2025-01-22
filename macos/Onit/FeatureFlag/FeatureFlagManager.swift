//
//  FeatureFlagManager.swift
//  Onit
//
//  Created by Kévin Naudin on 21/01/2025.
//

import PostHog
import Foundation

/**
 * Class which manages feature flags with PostHog SDK
 */
final class FeatureFlagManager: Sendable {
    
    // MARK: - Singleton instance
    
    static let shared = FeatureFlagManager()
    
    // MARK: - Functions
    
    /** Configure the SDK */
    func configure() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "PostHogApiKey") as? String,
              let host = Bundle.main.object(forInfoDictionaryKey: "PostHogHost") as? String else {
            log.error("PostHog -> Error not initialized due to missing API key or host")
            return
        }
        
        let config = PostHogConfig(apiKey: apiKey, host: host)
        
        PostHogSDK.shared.setup(config)
    }
    
    /** Reload / Fetch configuration */
    func reload() {
        PostHogSDK.shared.reloadFeatureFlags()
    }
    
    /**
     * Check if accessibility feature is enabled
     * - returns: True if accessibility is enabled, false otherwise
     */
    func isAccessibilityEnabled() -> Bool {
        // TODO: KNA - Add a fallback
        return PostHogSDK.shared.isFeatureEnabled("accessibility")
    }
}
