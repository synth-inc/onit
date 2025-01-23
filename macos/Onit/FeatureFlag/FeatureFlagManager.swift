//
//  FeatureFlagManager.swift
//  Onit
//
//  Created by Kévin Naudin on 21/01/2025.
//

import PostHog
import Foundation
import SwiftUI

/**
 * Class which manages feature flags with PostHog SDK
 */
@MainActor
class FeatureFlagManager: ObservableObject {
    
    // MARK: - Singleton instance
    
    static let shared = FeatureFlagManager()
    
    // MARK: - Feature Flags
    
    @Published private(set) var flags: FeatureFlags = .init()
    
    struct FeatureFlags {
        var accessibility: Bool = false
    }
    
    // MARK: - Feature Flag Keys
    
    enum FeatureFlagKey {
        case accessibility
    }
    
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
    
    /** Override feature flag value (for testing or manual control) */
    func setFeatureFlag(_ value: Bool, for key: FeatureFlagKey) {
        var newFlags = flags
        
        switch key {
        case .accessibility:
            newFlags.accessibility = value
        }
        
        flags = newFlags
    }
    
    // MARK: - Objective-C Functions
    
    @objc private func receiveFeatureFlags() {
        setFeatureFlagsFromRemote()
    }
    
    // MARK: - Private functions
    
    private func setFeatureFlagsFromRemote() {
        let newFlags = FeatureFlags(
            accessibility: PostHogSDK.shared.isFeatureEnabled("accessibility")
        )
        
        self.flags = newFlags
    }
}
