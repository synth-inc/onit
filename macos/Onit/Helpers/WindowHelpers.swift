//
//  WindowHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 6/17/25.
//

import AppKit

struct WindowHelpers {
    static func getWindowApp(pid: pid_t) -> NSRunningApplication? {
        return NSRunningApplication(processIdentifier: pid)
    }
    
    static func getWindowName(window: AXUIElement) -> String {
        var localizedName: String? = nil
        
        if let pid = window.pid(),
           let appLocalizedName = getWindowApp(pid: pid)?.localizedName
        {
            localizedName = appLocalizedName
        }
        
        let windowTitle = window.title() ?? "Unknown Title"
        let windowAppName = window.appName() ?? localizedName ?? "Unknown App"
        let windowName = "\(windowTitle) - \(windowAppName)"
        return windowName
    }
    
    static func getWindowAppBundleUrl(window: AXUIElement) -> URL? {
        if let pid = window.pid(),
           let windowApp = getWindowApp(pid: pid)
        {
            return windowApp.bundleURL
        } else {
            return nil
        }
    }
    
    static func getWindowIcon(window: AXUIElement) -> NSImage? {
        if let appBundleUrl = getWindowAppBundleUrl(window: window) {
            return NSWorkspace.shared.icon(forFile: appBundleUrl.path)
        } else {
            return nil
        }
    }
}
