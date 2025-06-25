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
    @Published private(set) var usePinnedMode: Bool = true
    @Published private(set) var stopMode: StopMode = .removePartial

    // MARK: - Private initializer
    
    private init() { }
    
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

    func togglePinnedMode(_ enabled: Bool) {
        Defaults[.usePinnedMode] = enabled
        usePinnedMode = enabled
    }

    func setStopMode(_ mode: StopMode) {
        Defaults[.stopMode] = mode
        stopMode = mode
    }

    func setStopModeByUser(_ mode: StopMode) {
        Defaults[.stopMode] = mode
        Defaults[.stopModeUserConfigured] = true
        stopMode = mode
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
        
        // Handle pinned mode feature flag
        if let pinnedModeEnabled = Defaults[.usePinnedMode] {
            usePinnedMode = pinnedModeEnabled
        } else {
            let pinnedModeFlag = PostHogSDK.shared.isFeatureEnabled("pinned_mode")
            
            togglePinnedMode(pinnedModeFlag)
        }

        // Handle stop mode feature flag
        // Only use remote flag if user hasn't manually configured their preference
        if Defaults[.stopModeUserConfigured] {
            // User has manually set their preference, respect it
            let localStopMode = Defaults[.stopMode]
            stopMode = localStopMode
        } else {
            // User hasn't configured it, use remote feature flag
            if PostHogSDK.shared.isFeatureEnabled("stop_mode_leave_partial") {
                // Remote flag is enabled, use leavePartial
                setStopMode(.leavePartial)
            } else {
                // No remote override, use default
                setStopMode(.removePartial)
            }
        }
    }
}
