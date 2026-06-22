//
//  MenuBarVersion.swift
//  Onit
//
//  Created by Loyd Kim on 9/19/25.
//

import AppKit

final class MenuBarVersion: MenuBarItemBase {
    // MARK: - Initializer

    override func initializeProperties() {
        self.title = ""
        self.action = nil
        self.keyEquivalent = ""
        self.target = self
        self.isEnabled = false
    }

    override func runPostInitilizationSetup() {
        self.title = self.versionText
    }

    // MARK: - Private Variables

    @MainActor
    private var versionText: String {
        let version = Bundle.main.appVersion
        let build = Bundle.main.appBuild

        #if ONIT_BETA
        return String.localized("Version %@ (%@) - BETA", table: "MenuBar", version, build)
        #else
        return String.localized("Version %@", table: "MenuBar", version)
        #endif
    }
}
