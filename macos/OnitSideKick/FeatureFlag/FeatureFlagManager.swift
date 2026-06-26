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

    /// One-time migration to the new Pinned-by-default behavior. Existing users
    /// carry a persisted `usePinnedMode` (often Tethered), which would otherwise
    /// override the new default forever, so flip them to Pinned exactly once.
    /// They remain free to switch back in Settings afterward.
    private func migratePinnedDefaultIfNeeded() {
        guard !Defaults[.hasMigratedToPinnedDefault] else { return }
        togglePinnedMode(true)
        Defaults[.hasMigratedToPinnedDefault] = true
    }

    /** Configure the SDK */
    func configure() {
        migratePinnedDefaultIfNeeded()

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

        // Handle pinned mode. SideKick defaults new users to Pinned mode: it's
        // the more reliable positioning mode (Tethered window-following is fragile).
        // Respect an explicit user choice if one has been persisted.
        if let pinnedModeEnabled = Defaults[.usePinnedMode] {
            usePinnedMode = pinnedModeEnabled
        } else {
            togglePinnedMode(true)
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
