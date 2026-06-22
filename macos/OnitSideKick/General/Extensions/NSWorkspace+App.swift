//
//  NSWorkspace+App.swift
//  Onit
//
//  Created by Kévin Naudin on 23/12/2025.
//

import AppKit

extension NSWorkspace {
    /// Returns the icon for an application given its bundle identifier
    func icon(forBundleIdentifier bundleId: String) -> NSImage? {
        guard let appURL = urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }
        return icon(forFile: appURL.path)
    }

    /// Returns the app name for an application given its bundle identifier
    func appName(forBundleIdentifier bundleId: String) -> String? {
        guard let appURL = urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }
        return FileManager.default.displayName(atPath: appURL.path)
            .replacingOccurrences(of: ".app", with: "")
    }
}
