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
@MainActor
class FeatureFlagManager {
    
    // MARK: - Singleton instance
    
    static let shared = FeatureFlagManager()
    
    private var isReadyToUse = false
    
    // MARK: - Functions
    
    /** Configure the SDK */
    func configure() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "PostHogApiKey") as? String,
              let host = Bundle.main.object(forInfoDictionaryKey: "PostHogHost") as? String else {
            print("PostHog -> Error not initialized due to missing API key or host")
            return
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveFeatureFlags),
            name: PostHogSDK.didReceiveFeatureFlags,
            object: nil
        )
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
        guard isReadyToUse else { return false }
        
        return PostHogSDK.shared.isFeatureEnabled("accessibility")
    }
    
    @objc func receiveFeatureFlags() {
        self.isReadyToUse = true
    }
}
