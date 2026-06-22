//
//  MenuBarFeatureEnable.swift
//  Onit
//
//  Created by Loyd Kim on 9/24/25.
//

import AppKit
import Defaults

@MainActor
final class MenuBarFeatureEnable: MenuBarItemBase {
    // MARK: - Initializer

    override func initializeProperties() {
        self.title = ""
        self.action = nil
        self.keyEquivalent = ""
        self.target = self
    }

    override func runPostInitilizationSetup() {
        self.setMenuItemTitleAndAction()
    }

    // MARK: - States

    private var appDisableRule: AppDisableRule? = nil
    private var currentDisableRule: FeatureDisableRule? = nil
    private var dropdownSubmenu = NSMenu()

    // MARK: - Private Variables

    private let featureDisableManager = FeatureDisableManager.shared
    private let analyticsSource = "AppMenu"

    // MARK: - Private Functions

    @objc private func enableInPrivateBrowsing() {
        // Disable private browser setting for menu default features
        if DisableableFeature.menuDefault.contains(.sidekick) {
            Defaults[.sidekickDisabledInPrivateBrowser] = false
        }
    }

    @objc private func enableEverywhere() {
        self.featureDisableManager.removeDisableRule(for: .menuDefault)
    }

    @objc private func enableForApp() {
        guard let app = self.appDisableRule else { return }

        self.featureDisableManager.removeDisableRule(for: .menuDefault, app: app)
    }

    @objc private func enableOnce() {
        guard let disableRule = self.currentDisableRule else { return }

        self.featureDisableManager.addIgnoredDisableRule(for: disableRule, isEnableOnce: true)
    }

    private func populateDropdownSubmenu(enableAction: Selector, enableTitle: String) {
        self.dropdownSubmenu.removeAllItems()

        // Enable permanently option
        let enableItem = NSMenuItem(
            title: enableTitle,
            action: enableAction,
            keyEquivalent: ""
        )
        enableItem.target = self
        self.dropdownSubmenu.addItem(enableItem)

        // Enable once option
        let enableOnceItem = NSMenuItem(
            title: String.localized("Enable Once", table: "MenuBar"),
            action: #selector(enableOnce),
            keyEquivalent: ""
        )
        enableOnceItem.target = self
        self.dropdownSubmenu.addItem(enableOnceItem)

        self.submenu = self.dropdownSubmenu
    }

    private func setMenuItemTitleAndAction() {
        let status = self.featureDisableManager.currentDisableStatus(for: .menuDefault)
        self.currentDisableRule = self.featureDisableManager.findDisableRule(for: .menuDefault)

        switch status {
        case .disabledInPrivateBrowsing:
            self.appDisableRule = nil
            self.currentDisableRule = nil
            self.title = String.localized("Enable in Private Browsing", table: "MenuBar")
            self.action = #selector(enableInPrivateBrowsing)
            self.submenu = nil

        case .disabledGloballyIndefinitely,
                .disabledGloballyTemporarily(_),
                .disabledGloballyTimeRange(_, _):
            self.appDisableRule = nil
            self.title = String.localized("Enable Sidekick", table: "MenuBar")
            self.action = nil
            self.populateDropdownSubmenu(
                enableAction: #selector(enableEverywhere),
                enableTitle: String.localized("Enable Permanently", table: "MenuBar")
            )

        case .disabledForAppIndefinitely(let app),
                .disabledForAppTemporarily(let app, _),
                .disabledForAppTimeRange(let app, _, _):
            self.appDisableRule = app
            self.title = String.localized("Enable in %@", table: "MenuBar", app.name)
            self.action = nil
            self.populateDropdownSubmenu(
                enableAction: #selector(enableForApp),
                enableTitle: String.localized("Enable Permanently", table: "MenuBar")
            )

        case .notDisabled:
            self.appDisableRule = nil
            self.currentDisableRule = nil
            self.title = ""
            self.action = nil
            self.submenu = nil
        }
    }
}
