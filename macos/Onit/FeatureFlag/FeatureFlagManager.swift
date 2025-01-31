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
    
    @Published private(set) var accessibility: Bool = false
    @Published private(set) var accessibilityInput: Bool = false
    @Published private(set) var accessibilityAutoContext: Bool = false
    @Published private(set) var highlightHintMode: HighlightHintMode = .none
    
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
    
    func overrideAccessibility(_ value: Bool) {
        let preferences = Preferences.shared
        preferences.accessibilityEnabled = value
        Preferences.save(preferences)
        
        accessibility = value
    }
    
    func overrideAccessibilityInput(_ value: Bool) {
        let preferences = Preferences.shared
        preferences.accessibilityInputEnabled = value
        Preferences.save(preferences)
        
        accessibilityInput = value
    }
    
    func overrideAccessibilityAutoContext(_ value: Bool) {
        let preferences = Preferences.shared
        preferences.accessibilityAutoContextEnabled = value
        Preferences.save(preferences)
        
        accessibilityAutoContext = value
    }
    
    func overrideHighlightHintMode(_ value: HighlightHintMode) {
        let preferences = Preferences.shared
        preferences.highlightHintMode = value
        Preferences.save(preferences)
        
        highlightHintMode = value
    }
    
    // MARK: - Objective-C Functions
    
    @objc private func receiveFeatureFlags() {
        setFeatureFlagsFromRemote()
    }
    
    // MARK: - Private functions
    
    private func setFeatureFlagsFromRemote() {
        if let accessibilityEnabled = Preferences.shared.accessibilityEnabled {
            accessibility = accessibilityEnabled
        } else {
            accessibility = PostHogSDK.shared.isFeatureEnabled("accessibility")
        }
        
        if let accessibilityInputEnabled = Preferences.shared.accessibilityInputEnabled {
            accessibilityInput = accessibilityInputEnabled
        } else {
            accessibilityInput = PostHogSDK.shared.isFeatureEnabled("accessibility_input")
        }
        
        if let accessibilityAutoContextEnabled = Preferences.shared.accessibilityAutoContextEnabled {
            accessibilityAutoContext = accessibilityAutoContextEnabled
        } else {
            accessibilityAutoContext = PostHogSDK.shared.isFeatureEnabled("accessibility_autocontext")
        }
        
        if let highlightHintMode = Preferences.shared.highlightHintMode {
            self.highlightHintMode = highlightHintMode
        } else {
            if let value = PostHogSDK.shared.getFeatureFlag("highlight_hint_mode") as? String,
               let mode = HighlightHintMode(rawValue: value) {
                self.highlightHintMode = mode
            } else {
                self.highlightHintMode = .none
            }
        }
    }
}
