//
//  MenuBarCheckForPermissions.swift
//  Onit
//
//  Created by Loyd Kim on 9/25/25.
//

import AppKit

final class MenuBarCheckForPermissions: MenuBarItemBase {
    // MARK: - Initializer

    override func initializeProperties() {
        self.title = ""
        self.image = self.statusDot
        self.action = #selector(openPermissionSettings)
        self.keyEquivalent = ""
        self.target = self
    }

    override func runPostInitilizationSetup() {
        self.title = String.localized(" Allow access...", table: "MenuBar")
    }

    // MARK: - Private Variables

    private lazy var statusDot = self.drawStatusDot(NSColor.red500)

    // MARK: - Private Functions

    @MainActor
    @objc private func openPermissionSettings() {
        if AccessibilityPermissionManager.shared.accessibilityPermissionStatus != .granted {
            AccessibilityPermissionManager.shared.requestPermission()
        }
    }
}
