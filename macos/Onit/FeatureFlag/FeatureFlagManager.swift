//
//  FeatureFlagManager.swift
//  Onit
//
//  Created by Kévin Naudin on 21/01/2025.
//

import Defaults
import Foundation
import PostHog
import SwiftUI

/// Class which manages feature flags with PostHog SDK
@MainActor
class FeatureFlagManager: ObservableObject {

    // MARK: - Singleton instance

    static let shared = FeatureFlagManager()

    // MARK: - Feature Flags

    @Published private(set) var accessibilityInput: Bool = false
    @Published private(set) var accessibilityAutoContext: Bool = false
    @Published private(set) var highlightHintMode: HighlightHintMode = .none

    @Published private(set) var accessibility: Bool = false

    private var wasAccessibilityInputEnabled: Bool = false
    private var wasAccessibilityAutoContextEnabled: Bool = false

    // MARK: - Functions

    /** Configure the SDK */
    func configure() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "PostHogApiKey") as? String,
            let host = Bundle.main.object(forInfoDictionaryKey: "PostHogHost") as? String
        else {
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

    func overrideAccessibilityInput(_ value: Bool) {
        Defaults[.accessibilityInputEnabled] = value

        accessibilityInput = value
    }

    func overrideAccessibilityAutoContext(_ value: Bool) {
        Defaults[.accessibilityAutoContextEnabled] = value

        accessibilityAutoContext = value
    }

    func overrideHighlightHintMode(_ value: HighlightHintMode) {
        Defaults[.highlightHintMode] = value

        highlightHintMode = value
    }

    func overrideAccessibility(_ value: Bool) {
        Defaults[.accessibilityEnabled] = value

        accessibility = value

        if value {
            // Restore previous accessibility settings
            overrideAccessibilityInput(wasAccessibilityInputEnabled)
            overrideAccessibilityAutoContext(wasAccessibilityAutoContextEnabled)
        } else {
            // Store current settings before disabling
            wasAccessibilityInputEnabled = accessibilityInput
            wasAccessibilityAutoContextEnabled = accessibilityAutoContext

            // Disable all accessibility features
            overrideAccessibilityInput(false)
            overrideAccessibilityAutoContext(false)
        }
    }

    // MARK: - Objective-C Functions

    @objc private func receiveFeatureFlags() {
        setFeatureFlagsFromRemote()
    }

    // MARK: - Private functions

    private func setFeatureFlagsFromRemote() {
        // Set global accessibility toggle
        if let accessibilityEnabled = Defaults[.accessibilityEnabled] {
            accessibility = accessibilityEnabled
        } else {
            accessibility = PostHogSDK.shared.isFeatureEnabled("accessibility")
        }

        // Only set individual accessibility features if global toggle is on
        if accessibility {
            if let accessibilityInputEnabled = Defaults[.accessibilityInputEnabled] {
                accessibilityInput = accessibilityInputEnabled
                wasAccessibilityInputEnabled = accessibilityInputEnabled
            } else {
                let enabled = PostHogSDK.shared.isFeatureEnabled("accessibility_input")
                accessibilityInput = enabled
                wasAccessibilityInputEnabled = enabled
            }

            if let accessibilityAutoContextEnabled = Defaults[.accessibilityAutoContextEnabled] {
                accessibilityAutoContext = accessibilityAutoContextEnabled
                wasAccessibilityAutoContextEnabled = accessibilityAutoContextEnabled
            } else {
                let enabled = PostHogSDK.shared.isFeatureEnabled("accessibility_autocontext")
                accessibilityAutoContext = enabled
                wasAccessibilityAutoContextEnabled = enabled
            }
        } else {
            // Store current settings but keep features disabled
            if let accessibilityInputEnabled = Defaults[.accessibilityInputEnabled] {
                wasAccessibilityInputEnabled = accessibilityInputEnabled
            } else {
                wasAccessibilityInputEnabled = PostHogSDK.shared.isFeatureEnabled(
                    "accessibility_input")
            }

            if let accessibilityAutoContextEnabled = Defaults[.accessibilityAutoContextEnabled] {
                wasAccessibilityAutoContextEnabled = accessibilityAutoContextEnabled
            } else {
                wasAccessibilityAutoContextEnabled = PostHogSDK.shared.isFeatureEnabled(
                    "accessibility_autocontext")
            }

            accessibilityInput = false
            accessibilityAutoContext = false
        }

        if let highlightHintMode = Defaults[.highlightHintMode] {
            self.highlightHintMode = highlightHintMode
        } else {
            if let value = PostHogSDK.shared.getFeatureFlag("highlight_hint_mode") as? String,
                let mode = HighlightHintMode(rawValue: value)
            {
                self.highlightHintMode = mode
            } else {
                self.highlightHintMode = .none
            }
        }
    }
}
