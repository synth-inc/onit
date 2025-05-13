//
//  AccessibilityAnalytics.swift
//  Onit
//
//  Created by Kévin Naudin on 19/02/2025.
//

import ApplicationServices
import AppKit
import Defaults
import PostHog

struct AccessibilityAnalytics {
    private static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
    
    @MainActor static func logPermission(local: AccessibilityPermissionStatus) {
        PostHogSDK.shared.capture("accessibility_permission_changes",
            properties: [
                "local_value": local.rawValue,
                "is_trusted": AXIsProcessTrusted(),
                "input_enabled": Defaults[.autoContextFromHighlights],
                "autocontext_enabled": Defaults[.autoContextFromCurrentWindow],
                "app_version": AccessibilityAnalytics.appVersion,
                "os_version": ProcessInfo.processInfo.operatingSystemVersionString
            ]
        )
    }
    
    @MainActor static func logFlags() {
        PostHogSDK.shared.capture("accessibility_flags_changes",
            properties: [
                "is_trusted": AXIsProcessTrusted(),
                "input_enabled": Defaults[.autoContextFromHighlights],
                "autocontext_enabled": Defaults[.autoContextFromCurrentWindow],
                "app_version": AccessibilityAnalytics.appVersion,
                "os_version": ProcessInfo.processInfo.operatingSystemVersionString
            ]
        )
    }
    
    @MainActor static func logObserverError(errorCode: Int32, pid: pid_t) {
        var properties: [String: Any] = [
            "error_code": errorCode,
            "is_trusted": AXIsProcessTrusted(),
            "input_enabled": Defaults[.autoContextFromHighlights],
            "autocontext_enabled": Defaults[.autoContextFromCurrentWindow],
            "app_version": AccessibilityAnalytics.appVersion,
            "os_version": ProcessInfo.processInfo.operatingSystemVersionString
        ]
        
        if let app = NSRunningApplication(processIdentifier: pid) {
            properties["app_name"] = app.localizedName
            properties["app_bundle_id"] = app.bundleIdentifier
        }
        
        PostHogSDK.shared.capture("accessibility_observer_error",
            properties: properties
        )
    }
} 
