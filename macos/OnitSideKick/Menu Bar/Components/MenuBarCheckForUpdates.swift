//
//  MenuBarCheckForUpdates.swift
//  Onit
//
//  Created by Loyd Kim on 9/19/25.
//

import AppKit
import Defaults

final class MenuBarCheckForUpdates: MenuBarItemBase, NSMenuItemValidation {
    // MARK: - Initializer

    override func initializeProperties() {
        self.title = ""
        self.action = #selector(checkForUpdates)
        self.keyEquivalent = ""
        self.target = self
    }

    override func runPostInitilizationSetup() {
        self.title = String.localized("Check for Updates", table: "MenuBar")
    }

    // MARK: - Conformance to `NSMenuItemValidation`

    /// Controls the `NSMenuItem`'s enabled state.
    /// If `canCheckForUpdates` is `true`, this menu item is enabled; otherwise, it's disabled.
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return self.appState.updater.updater.canCheckForUpdates
    }

    // MARK: - Private Variables

    @MainActor
    private var appState: AppState {
        AppState.shared
    }

    // MARK: - Private Functions

    @MainActor
    @objc private func checkForUpdates() {
        Defaults[.dismissedUpdateAlertVersion] = self.appState.availableUpdateVersion ?? ""
        self.appState.updater.updater.checkForUpdates()
    }
}
