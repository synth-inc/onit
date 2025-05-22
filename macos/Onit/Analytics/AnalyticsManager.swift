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
    
    static func appQuit() {
        Self.sendCommonEvent(event: "app_quit")
    }
}
