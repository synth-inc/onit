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

struct AnalyticsManager {
    static func getCommonProperties() -> [String: Any] {
        let deviceModel: String = {
            var size: size_t = 0
            sysctlbyname("hw.model", nil, &size, nil, 0)
            var model = [Int8](repeating: 0, count: size)
            sysctlbyname("hw.model", &model, &size, nil, 0)
            if let lastIndex = model.firstIndex(of: 0) {
                model.removeSubrange(lastIndex...)
            }
            return String(decoding: model.map(UInt8.init), as: UTF8.self)
        }()
        
        let cpuArchitecture: String = {
            var size: size_t = 0
            sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
            var buffer = [Int8](repeating: 0, count: size)
            sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0)
            if let lastIndex = buffer.firstIndex(of: 0) {
                buffer.removeSubrange(lastIndex...)
            }
            return String(decoding: buffer.map(UInt8.init), as: UTF8.self)
        }()

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
    
    static func appQuit() {
        let properties = Self.getCommonProperties()
        
        PostHogSDK.shared.capture("app_quit", properties: properties)
    }
}
