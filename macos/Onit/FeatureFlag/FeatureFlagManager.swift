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

    @Published private(set) var autocontextDemoVideoUrl: String? = nil
    @Published private(set) var useScreenModeWithAccessibility: Bool = false

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

    func toggleScreenModeWithAccessibility(_ enabled: Bool) {
        Defaults[.useScreenModeWithAccessibility] = enabled
        useScreenModeWithAccessibility = enabled
    }

    // MARK: - Objective-C Functions

    @objc private func receiveFeatureFlags() {
        setFeatureFlagsFromRemote()
    }

    // MARK: - Private functions

    private func setFeatureFlagsFromRemote() {
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
        
        useScreenModeWithAccessibility = Defaults[.useScreenModeWithAccessibility] ?? false
    }
}
