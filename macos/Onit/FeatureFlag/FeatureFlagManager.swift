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
    
    struct FeatureFlags: Codable {
        var accessibility: Bool = false
        var accessibilityInput: Bool = false
        var accessibilityAutoContext: Bool = false
    }
    
    // MARK: - Feature Flag Keys
    
    enum FeatureFlagKey: String, CaseIterable, Identifiable {
        var id : String { UUID().uuidString }
        
        case accessibility = "Accessibility"
        case accessibilityInput = "Accessibility Input"
        case accessibilityAutoContext = "Accessibility Auto Context"
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
    
    func getFeatureFlag(_ key: FeatureFlagKey) -> Bool {
        switch key {
        case .accessibility:
            return flags.accessibility
        case .accessibilityInput:
            return flags.accessibilityInput
        case .accessibilityAutoContext:
            return flags.accessibilityAutoContext
        }
    }
    
    /** Override feature flag value (for testing or manual control) */
    func overrideFeatureFlag(_ value: Bool, for key: FeatureFlagKey) {
        var newFlags = flags
        
        switch key {
        case .accessibility:
            newFlags.accessibility = value
        case .accessibilityInput:
            newFlags.accessibilityInput = value
        case .accessibilityAutoContext:
            newFlags.accessibilityAutoContext = value
        }
        
        flags = newFlags
        
        let preferences = Preferences.shared
        preferences.featureFlags = newFlags
        Preferences.save(preferences)
    }
    
    // MARK: - Objective-C Functions
    
    @objc private func receiveFeatureFlags() {
        setFeatureFlagsFromRemote()
    }
    
    // MARK: - Private functions
    
    private func setFeatureFlagsFromRemote() {
        guard let localFeatureFlags = Preferences.shared.featureFlags else {
            let newFlags = FeatureFlags(
                accessibility: PostHogSDK.shared.isFeatureEnabled("accessibility"),
                accessibilityInput: PostHogSDK.shared.isFeatureEnabled("accessibility_input"),
                accessibilityAutoContext: PostHogSDK.shared.isFeatureEnabled("accessibility_autocontext")
            )
            
            self.flags = newFlags
            return
        }
        
        self.flags = localFeatureFlags
    }
}
