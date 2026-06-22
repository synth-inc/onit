//
//  MenuBarFeatureDisable.swift
//  Onit
//
//  Created by Loyd Kim on 9/24/25.
//

import AppKit

@MainActor
final class MenuBarFeatureDisable: MenuBarItemBase {
    // MARK: - Properties

    private var foregroundWindow: TrackedWindow? = nil

    // MARK: - Initializer

    convenience init(foregroundWindow: TrackedWindow? = nil) {
        self.init(title: "", action: (nil as Selector?), keyEquivalent: "")
        self.foregroundWindow = foregroundWindow
    }

    override func initializeProperties() {
        self.title = ""
        self.action = nil
        self.keyEquivalent = ""
        self.target = self
    }

    override func runPostInitilizationSetup() {
        self.populateDropdownSubmenu()
        self.setMenuItemTitle()
    }

    // MARK: - States

    private var dropdownSubmenu = NSMenu()

    // MARK: - Private Variables

    private let featureDisableManager = FeatureDisableManager.shared
    private let featureDisableWindowManager = FeatureDisableWindowManager.shared

    private let oneMinute: TimeInterval = 60
    private let oneHour: TimeInterval = 60 * 60

    private var submenuItems: [(title: String, action: Selector)] {
        [
            (
                title: String.localized("For 5 mins", table: "MenuBar"),
                action: #selector(disableForFiveMinutes)
            ),
            (
                title: String.localized("For 15 mins", table: "MenuBar"),
                action: #selector(disableForFifteenMinutes)
            ),
            (
                title: String.localized("For 30 mins", table: "MenuBar"),
                action: #selector(disableForThirtyMinutes)
            ),
            (
                title: String.localized("Until Tomorrow", table: "MenuBar"),
                action: #selector(disableUntilTomorrow)
            ),
            (
                title: String.localized("Indefinitely", table: "MenuBar"),
                action: #selector(disableIndefinitely)
            ),
            (
                title: String.localized("Set Specific Hours...", table: "MenuBar"),
                action: #selector(openDisableEverywhereWindow)
            )
        ]
    }

    private var appName: String? {
        guard let window = self.foregroundWindow?.element else { return nil }
        return WindowHelpers.getWindowAppName(window: window)
    }

    // MARK: - Private Functions

    private func addSubmenuItem(_ item: NSMenuItem) {
        item.target = self
        self.dropdownSubmenu.addItem(item)
    }

    private func populateDropdownSubmenu() {
        self.dropdownSubmenu.removeAllItems()

        for submenuItem in self.submenuItems {
            self.addSubmenuItem(
                NSMenuItem(
                title: submenuItem.title,
                action: submenuItem.action,
                keyEquivalent: ""
                )
            )
        }

        self.submenu = self.dropdownSubmenu
    }

    private func setMenuItemTitle() {
        let status = self.featureDisableManager.currentDisableStatus(for: .menuDefault)

        switch status {
        case .notDisabled:
            if let appName = self.appName {
                self.title = String.localized("Disable Sidekick in %@", table: "MenuBar", appName)
            } else {
                self.title = String.localized("Disable Sidekick Everywhere", table: "MenuBar")
            }
        default:
            self.title = ""
        }
    }

    private func handleDisableFeature(
        disableRuleExpiresIn: TimeInterval? = nil,
        expirationDurationText: String? = nil
    ) {
        let appDisableRule = self.featureDisableManager.createAppDisableRule(self.foregroundWindow)
        var disableRuleExpirationDate: Date? = nil

        if let expiresIn = disableRuleExpiresIn {
            disableRuleExpirationDate = DateHelpers.getExpirationDate(expiresIn: expiresIn)
        }

        self.featureDisableManager.addDisableRule(
            features: .menuDefault,
            app: appDisableRule,
            expirationDate: disableRuleExpirationDate
        )
    }

    @objc private func disableForFiveMinutes() {
        let fiveMinutes = self.oneMinute * 5

        self.handleDisableFeature(
            disableRuleExpiresIn: fiveMinutes,
            expirationDurationText: "5 minutes"
        )
    }

    @objc private func disableForFifteenMinutes() {
        let fifteenMinutes = self.oneMinute * 15

        self.handleDisableFeature(
            disableRuleExpiresIn: fifteenMinutes,
            expirationDurationText: "15 minutes"
        )
    }

    @objc private func disableForThirtyMinutes() {
        let thirtyMinutes = self.oneMinute * 30

        self.handleDisableFeature(
            disableRuleExpiresIn: thirtyMinutes,
            expirationDurationText: "30 minutes"
        )
    }

    @objc private func disableUntilTomorrow() {
        let twentyFourHours = self.oneHour * 24

        self.handleDisableFeature(
            disableRuleExpiresIn: twentyFourHours,
            expirationDurationText: "24 hours"
        )
    }

    @objc private func disableIndefinitely() {
        self.handleDisableFeature()
    }

    @objc private func openDisableEverywhereWindow() {
        self.featureDisableWindowManager.createWindow(
            foregroundWindow: self.foregroundWindow,
            disableType: .setSpecificHours
        )
    }
}
