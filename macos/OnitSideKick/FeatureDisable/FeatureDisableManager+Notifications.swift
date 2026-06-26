//
//  FeatureDisableManager+Notifications.swift
//  Onit
//
//  Created by Kévin Naudin on 27/01/2026.
//

import Defaults

extension FeatureDisableManager {
    // MARK: - Notification Window Contents

    private func getDisabledNotificationWindowContents(
        for feature: DisableableFeature
    ) -> (
        titleKey: String,
        captionKey: String?,
        action: NotificationWindowView.Action
    ) {
        let titleKey: String = String.localized("You have disabled SideKick", table: "MenuBar")

        var captionKey: String? = nil

        var action: NotificationWindowView.Action = (
            textKey: String.localized("Enable", table: "MenuBar"),
            shouldCloseWindow: true,
            callback: nil
        )

        let status = self.currentDisableStatus(for: feature)

        switch status {
        case .disabledInPrivateBrowsing:
            captionKey = String.localized("Disabled in private browsers", table: "MenuBar")
            action.callback = { self.disablePrivateBrowserSetting(for: feature) }

        case .disabledGloballyIndefinitely:
            captionKey = String.localized("Everywhere, indefinitely", table: "MenuBar")
            action.callback = { self.removeDisableRule(for: feature) }

        case .disabledGloballyTemporarily(let expirationDate):
            let expirationText = DateHelpers.formatDateToTimeRemaining(expirationDate)
            captionKey = String.localized("Everywhere, %@", table: "MenuBar", expirationText)
            action.callback = { self.removeDisableRule(for: feature) }

        case .disabledGloballyTimeRange(let startTime, let endTime):
            let startTimeText = DateHelpers.formatDateToTimeOfDay(startTime)
            let endTimeText = DateHelpers.formatDateToTimeOfDay(endTime)
            captionKey = String.localized("Everywhere, between %@ - %@", table: "MenuBar", startTimeText, endTimeText)
            action.textKey = String.localized("Enable Once", table: "MenuBar")

            if let disableRule = self.findDisableRule(for: feature) {
                action.callback = {
                    self.addIgnoredDisableRule(
                        for: disableRule,
                        ignoredUntil: endTime
                    )
                }
            }

        case .disabledForAppIndefinitely(let app):
            captionKey = String.localized("In %@, indefinitely", table: "MenuBar", app.name)
            action.callback = { self.removeDisableRule(for: feature, app: app) }

        case .disabledForAppTemporarily(let app, let expirationDate):
            let expirationText = DateHelpers.formatDateToTimeRemaining(expirationDate)
            captionKey = String.localized("In %@, %@", table: "MenuBar", app.name, expirationText)
            action.callback = { self.removeDisableRule(for: feature, app: app) }

        case .disabledForAppTimeRange(let app, let startTime, let endTime):
            let startTimeText = DateHelpers.formatDateToTimeOfDay(startTime)
            let endTimeText = DateHelpers.formatDateToTimeOfDay(endTime)
            captionKey = String.localized("In %@, between %@ - %@", table: "MenuBar", app.name, startTimeText, endTimeText)
            action.textKey = String.localized("Enable Once", table: "MenuBar")

            if let disableRule = self.findDisableRule(for: feature) {
                action.callback = {
                    self.addIgnoredDisableRule(
                        for: disableRule,
                        ignoredUntil: endTime
                    )
                }
            }

        case .notDisabled:
            break
        }

        return (
            titleKey: titleKey,
            captionKey: captionKey,
            action: action
        )
    }

    // MARK: - Private Browser Setting

    private func disablePrivateBrowserSetting(for feature: DisableableFeature) {
        switch feature {
        case .sidekick:
            Defaults[.sidekickDisabledInPrivateBrowser] = false
        default:
            break
        }
    }

    // MARK: - Create Notification

    func createDisabledNotification(for feature: DisableableFeature) {
        let status = currentDisableStatus(for: feature)
        guard status != .notDisabled else { return }

        let featureName: String
        switch feature {
        case .sidekick:
            featureName = "Sidekick"
        default:
            featureName = "Feature"
        }

        let namedIdentifier = "\(featureName) Manual Summon Disabled Notification"

        NotificationWindowManager.shared.closeWindows(referencing: namedIdentifier)

        let (titleKey, captionKey, action) = self.getDisabledNotificationWindowContents(for: feature)

        NotificationWindowManager.shared.createWindow(
            titleKey: titleKey,
            captionKey: captionKey,
            primaryAction: action,
            namedIdentifier: namedIdentifier,
            enterAnimation: NotificationWindowAnimation(direction: .right),
            dismissAnimation: NotificationWindowAnimation(direction: .right)
        )
    }
}
