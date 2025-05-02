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

    @Published private(set) var highlightHintMode: HighlightHintMode = .none
    @Published private(set) var autocontextDemoVideoUrl: String? = nil
    
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

    func overrideHighlightHintMode(_ value: HighlightHintMode) {
        Defaults[.highlightHintMode] = value

        highlightHintMode = value
    }

    // MARK: - Objective-C Functions

    @objc private func receiveFeatureFlags() {
        setFeatureFlagsFromRemote()
    }

    // MARK: - Private functions

    private func setFeatureFlagsFromRemote() {
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

        // Get demo video URL from feature flag
        if let rawValue = PostHogSDK.shared.getFeatureFlagPayload("autocontext_demo_video_url") {
            if let payload = rawValue as? [String: Any], let urlString = payload["url"] as? String {
                autocontextDemoVideoUrl = urlString
            } else {
                autocontextDemoVideoUrl = nil
            }
        } else {
            autocontextDemoVideoUrl = nil
        }
    }
}
