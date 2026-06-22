//
//  AnalyticsManager.swift
//  Onit
//
//  Created by Kévin Naudin on 21/05/2025.
//

import ApplicationServices
import AppKit
import Defaults
import PostHog

/**
 * This class is used to track analytics event using PostHog SDK
 */
struct AnalyticsManager {
    static func getCommonProperties() -> [String: Any] {
        func getSystemInfo(name: String, defaultValue: String) -> String {
            var size: size_t = 0
            var result = sysctlbyname(name, nil, &size, nil, 0)
            
            guard result != -1 else { return defaultValue }
            
            var buffer = [Int8](repeating: 0, count: size)
            result = sysctlbyname(name, &buffer, &size, nil, 0)
            
            guard result != -1 else { return defaultValue }
            
            if let lastIndex = buffer.firstIndex(of: 0) {
                buffer.removeSubrange(lastIndex...)
            }
            return String(decoding: buffer.map(UInt8.init), as: UTF8.self)
        }
        
        let deviceModel = getSystemInfo(name: "hw.model", defaultValue: "Unknown")
        let cpuArchitecture = getSystemInfo(name: "machdep.cpu.brand_string", defaultValue: "Unknown")
        let screenCount = NSScreen.screens.count

        return [
            "device_model": deviceModel,
            "cpu_architecture": cpuArchitecture,
            "screen_count": screenCount,
            "accessibility_trusted": AXIsProcessTrusted(),
            "accessibility_highlight_enabled": Defaults[.autoContextFromHighlights],
            "accessibility_autocontext_enabled": Defaults[.autoContextFromCurrentWindow]
        ]
    }
    
    static func sendCommonEvent(event: String) {
        let properties = Self.getCommonProperties()

        PostHogSDK.shared.capture(event, properties: properties)
    }

    /// Strip macOS file-system paths (`/Users/<username>/...`,
    /// `/Volumes/<vol>/Users/<username>/...`) and file-URL variants from
    /// strings before they hit PostHog. The username segment is PII per
    /// most internal rubrics, and Apple's `NSError.localizedDescription`
    /// frequently embeds these paths verbatim (download errors, file-write
    /// failures, etc.). Keeps the rest of the description intact so the
    /// debuggability story still works — only the username is redacted.
    static func scrubPaths(_ message: String) -> String {
        // Capture `/Users/<username>` (optionally prefixed by `file://`)
        // and replace just the username segment with `<redacted>`. The
        // trailing path stays so the failure context (e.g. which subdir)
        // is still useful.
        let pattern = #"(file://)?(/Users/)([^/\s)>"']+)"#
        return message.replacingOccurrences(
            of: pattern,
            with: "$1$2<redacted>",
            options: .regularExpression
        )
    }
    
    @MainActor
    static func appQuit() {
        guard !shouldSuppressAppQuitForOnboardingPermissionsStep() else { return }
        Self.sendCommonEvent(event: "app_quit")
    }

    @MainActor
    private static func shouldSuppressAppQuitForOnboardingPermissionsStep() -> Bool {
        guard !OnboardingStep.isOnboardingComplete else { return false }
        return Defaults[.currentOnboardingStep] == .permissions
    }
}
