//
//  AnalyticsManager+Accessibility.swift
//  Onit
//
//  Created by Kévin Naudin on 19/02/2025.
//

import ApplicationServices
import AppKit
import Defaults
import PostHog

extension AnalyticsManager {
    @MainActor static func logAXPermission(local: AccessibilityPermissionStatus) {
        var properties = Self.getCommonProperties()
        
        properties["local_value"] = local.rawValue
        
        PostHogSDK.shared.capture("accessibility_permission_changes", properties: properties)
    }
    
    @MainActor static func logAXFlags() {
        let properties = Self.getCommonProperties()
        
        PostHogSDK.shared.capture("accessibility_flags_changes", properties: properties)
    }
    
    @MainActor static func logAXParseTimedOut(appName: String) {
        var properties = Self.getCommonProperties()
        
        properties["app_name"] = appName
        
        PostHogSDK.shared.capture("accessibility_parse_timed_out", properties: properties)
    }
    
    @MainActor static func logAXServerInitializationError(app: NSRunningApplication) {
        func findAccessibilityInspectorAppURL() -> URL? {
            let workspace = NSWorkspace.shared
            let bundleIdentifier = "com.apple.AccessibilityInspector"
            
            return workspace.urlForApplication(withBundleIdentifier: bundleIdentifier)
        }
        
        let hasAccessibilityInspector = findAccessibilityInspectorAppURL() != nil ? true : false
        var properties = Self.getCommonProperties()
        
        properties["accessibility_inspector_available"] = hasAccessibilityInspector
        
        if let appName = app.localizedName {
            properties["app_name"] = appName
        }
        if let appBundle = app.bundleIdentifier {
            properties["app_bundle_id"] = appBundle
        }
        
        PostHogSDK.shared.capture("accessibility_not_fully_initialized_error", properties: properties)
    }
    
    @MainActor static func logAXObserverError(errorCode: Int32, pid: pid_t) {
        var properties = Self.getCommonProperties()
        properties["error_code"] = errorCode
        
        if let app = NSRunningApplication(processIdentifier: pid) {
            properties["app_name"] = app.localizedName
            properties["app_bundle_id"] = app.bundleIdentifier
        }
        
        PostHogSDK.shared.capture("accessibility_observer_error", properties: properties)
    }
}
