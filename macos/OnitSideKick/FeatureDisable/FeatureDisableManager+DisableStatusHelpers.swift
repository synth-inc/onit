//
//  FeatureDisableManager+DisableStatusHelpers.swift
//  Onit
//
//  Created by Kévin Naudin on 27/01/2026.
//

import Defaults
import Foundation

// MARK: - FeatureDisableManager Disable Status Helpers

extension FeatureDisableManager {
    // MARK: - Foreground Window Tracking

    func setupForegroundWindowTracking() {
        let windowChangeDelegate = WindowChangeDelegate { [weak self] windowChangeInfo in
            self?.trackedForegroundWindow = windowChangeInfo.trackedWindow
        }

        self.windowChangeDelegate = windowChangeDelegate
        AccessibilityNotificationsManager.shared.addDelegate(windowChangeDelegate)
    }

    // MARK: - Private Browsing Check

    func checkDisabledInPrivateBrowsing(for feature: DisableableFeature) -> Bool {
        guard PrivacyManager.shared.isCurrentWindowPrivate else { return false }

        // Read directly from Defaults to ensure we have the latest value
        switch feature {
        case .sidekick:
            return Defaults[.sidekickDisabledInPrivateBrowser]
        default:
            return false
        }
    }

    // MARK: - Find Disable Rules

    func findGlobalDisableRule(for feature: DisableableFeature) -> FeatureDisableRule? {
        return self.featureDisableRules.first { rule in
            rule.app == nil && rule.features.contains(feature)
        }
    }

    private func findAppDisableRule(for feature: DisableableFeature) -> FeatureDisableRule? {
        guard let foregroundWindow = self.trackedForegroundWindow ?? PanelStateCoordinator.shared.state.foregroundWindow,
              let foregroundWindowAsAppDisableRule = self.createAppDisableRule(foregroundWindow)
        else {
            return nil
        }

        return self.featureDisableRules.first { rule in
            guard let appDisableRule = rule.app else { return false }
            return appDisableRule == foregroundWindowAsAppDisableRule && rule.features.contains(feature)
        }
    }

    func findDisableRule(for feature: DisableableFeature) -> FeatureDisableRule? {
        if let globalDisableRule = self.findGlobalDisableRule(for: feature) {
            return globalDisableRule
        } else if let appDisableRule = self.findAppDisableRule(for: feature) {
            return appDisableRule
        } else {
            return nil
        }
    }

    // MARK: - Ignored Rules Check

    private func checkActiveIgnoredRuleExists(for disableRule: FeatureDisableRule) -> Bool {
        let now = Date()

        return self.ignoredFeatureDisableRules.contains { ignoredRule in
            ignoredRule.disableRuleId == disableRule.id && ignoredRule.ignoredUntil > now
        }
    }

    // MARK: - Status Determination

    func determineDisableStatusFromRule(_ disableRule: FeatureDisableRule) -> FeatureDisableStatus {
        if self.checkActiveIgnoredRuleExists(for: disableRule) {
            return .notDisabled
        } else if let expirationDate = disableRule.expirationDate {
            if let app = disableRule.app {
                return .disabledForAppTemporarily(app: app, expirationDate: expirationDate)
            } else {
                return .disabledGloballyTemporarily(expirationDate: expirationDate)
            }
        } else if let timeRange = disableRule.timeRange {
            let startTime = timeRange.startTime
            let endTime = timeRange.endTime

            if let app = disableRule.app {
                return .disabledForAppTimeRange(app: app, startTime: startTime, endTime: endTime)
            } else {
                return .disabledGloballyTimeRange(startTime: startTime, endTime: endTime)
            }
        } else {
            if let app = disableRule.app {
                return .disabledForAppIndefinitely(app: app)
            } else {
                return .disabledGloballyIndefinitely
            }
        }
    }
}
