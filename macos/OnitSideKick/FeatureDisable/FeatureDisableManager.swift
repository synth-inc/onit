//
//  FeatureDisableManager.swift
//  Onit
//
//  Created by Kévin Naudin on 27/01/2026.
//

import Defaults
import DefaultsMacros
import Foundation
import SwiftUI

@MainActor
@Observable
final class FeatureDisableManager {
    // MARK: - Singleton

    static let shared = FeatureDisableManager()

    // MARK: - Properties (scheduling)

    @ObservationIgnored
    var disableRulesObserverTimer: Timer? = nil

    @ObservationIgnored
    var systemLevelObservers: [NSObjectProtocol] = []

    @ObservationIgnored
    var windowChangeDelegate: WindowChangeDelegate? = nil

    var trackedForegroundWindow: TrackedWindow? = nil

    // MARK: - Observables

    @ObservableDefault(.featureDisableRules)
    @ObservationIgnored
    var featureDisableRules: [FeatureDisableRule]

    @ObservableDefault(.ignoredFeatureDisableRules)
    @ObservationIgnored
    var ignoredFeatureDisableRules: [IgnoredFeatureDisableRule]

    @ObservableDefault(.sidekickDisabledInPrivateBrowser)
    @ObservationIgnored
    var sidekickDisabledInPrivateBrowser: Bool

    // MARK: - Initialization

    init() {
        self.initializeDisableObservers()
        self.setupForegroundWindowTracking()
    }

    // MARK: - Public Functions

    /// Check if a feature is currently enabled (not disabled by any rule)
    func isEnabled(_ feature: DisableableFeature) -> Bool {
        let status = currentDisableStatus(for: feature)

        switch status {
        case .notDisabled:
            return true
        case .disabledGloballyTimeRange(let startTime, let endTime),
             .disabledForAppTimeRange(_, let startTime, let endTime):
            let isWithinDisabledTimeRange = self.checkIsWithinDisabledTimeRange(
                DisableRuleTimeRange(startTime: startTime, endTime: endTime)
            )
            return !isWithinDisabledTimeRange
        default:
            return false
        }
    }

    /// Get the current disable status for a specific feature
    func currentDisableStatus(for feature: DisableableFeature) -> FeatureDisableStatus {
        if self.checkDisabledInPrivateBrowsing(for: feature) {
            return .disabledInPrivateBrowsing
        } else if let disableRule = self.findDisableRule(for: feature) {
            return determineDisableStatusFromRule(disableRule)
        } else {
            return .notDisabled
        }
    }

    /// Add a disable rule for specified features
    func addDisableRule(
        features: DisableableFeature,
        app: AppDisableRule? = nil,
        expirationDate: Date? = nil,
        timeRange: DisableRuleTimeRange? = nil
    ) {
        if let app = app {
            self.addAppDisableRule(
                features: features,
                app: app,
                expirationDate: expirationDate,
                timeRange: timeRange
            )
        } else {
            self.addGlobalDisableRule(
                features: features,
                expirationDate: expirationDate,
                timeRange: timeRange
            )
        }
    }

    /// Remove a disable rule for specified features
    func removeDisableRule(for features: DisableableFeature, app: AppDisableRule? = nil) {
        if let app = app {
            self.removeAppDisableRule(features: features, app: app)
        } else {
            self.removeGlobalDisableRule(features: features)
        }
    }

    /// Create an AppDisableRule from a tracked window
    func createAppDisableRule(_ window: TrackedWindow?) -> AppDisableRule? {
        guard let window = window else { return nil }

        let appName = WindowHelpers.getWindowAppName(window: window.element)

        return AppDisableRule(
            name: appName,
            bundleId: window.pid.bundleIdentifier,
            bundleUrl: WindowHelpers.getWindowAppBundleUrl(window: window.element),
            executableUrl: WindowHelpers.getWindowExecutableUrl(window: window.element)
        )
    }

    /// Add an ignored rule ("Enable Once")
    func addIgnoredDisableRule(
        for disableRule: FeatureDisableRule,
        ignoredUntil: Date = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Date()
        ) ?? Date().addingTimeInterval(60 * 60 * 24),
        isEnableOnce: Bool = false
    ) {
        let now = Date()
        guard ignoredUntil > now else { return }

        var currentIgnoredRules = self.ignoredFeatureDisableRules

        // Remove expired ignored rules
        currentIgnoredRules.removeAll { $0.ignoredUntil <= now }
        // Remove existing ignored rule for this disable rule
        currentIgnoredRules.removeAll { $0.disableRuleId == disableRule.id }

        let newIgnoredRule = IgnoredFeatureDisableRule(
            disableRuleId: disableRule.id,
            ignoredUntil: ignoredUntil,
            isEnableOnce: isEnableOnce
        )

        currentIgnoredRules.append(newIgnoredRule)
        self.ignoredFeatureDisableRules = currentIgnoredRules
        self.refreshDisableRulesStates()
    }

    /// Remove an ignored rule
    func removeIgnoredDisableRule(for ignoredRuleId: UUID) {
        var currentIgnoredRules = self.ignoredFeatureDisableRules
        currentIgnoredRules.removeAll { $0.id == ignoredRuleId }
        self.ignoredFeatureDisableRules = currentIgnoredRules
        self.refreshDisableRulesStates()
    }

    /// Clear "enable once" ignored rules for a feature after it has been used
    func clearEnableOnceRules(for feature: DisableableFeature) {
        guard let disableRule = findDisableRule(for: feature) else { return }

        var currentIgnoredRules = self.ignoredFeatureDisableRules
        let originalCount = currentIgnoredRules.count

        currentIgnoredRules.removeAll {
            $0.disableRuleId == disableRule.id && $0.isEnableOnce
        }

        // Only update if something was actually removed
        if currentIgnoredRules.count < originalCount {
            self.ignoredFeatureDisableRules = currentIgnoredRules
            self.refreshDisableRulesStates()
        }
    }

    // MARK: - Private Functions

    private func addGlobalDisableRule(
        features: DisableableFeature,
        expirationDate: Date? = nil,
        timeRange: DisableRuleTimeRange? = nil
    ) {
        let globalDisableRule = FeatureDisableRule(
            features: features,
            expirationDate: expirationDate,
            timeRange: timeRange
        )

        // Remove existing global rules for the same features
        self.removeGlobalRulesForFeatures(features)
        self.featureDisableRules.append(globalDisableRule)
        self.refreshDisableRulesStates()
    }

    private func addAppDisableRule(
        features: DisableableFeature,
        app: AppDisableRule,
        expirationDate: Date? = nil,
        timeRange: DisableRuleTimeRange? = nil
    ) {
        let appDisableRule = FeatureDisableRule(
            features: features,
            app: app,
            expirationDate: expirationDate,
            timeRange: timeRange
        )

        // Remove existing app rules for the same app and features
        self.removeDuplicateAppDisableRules(newRule: appDisableRule, features: features)
        self.featureDisableRules.append(appDisableRule)
        self.refreshDisableRulesStates()
    }

    private func removeGlobalDisableRule(features: DisableableFeature) {
        self.removeGlobalRulesForFeatures(features)
        self.refreshDisableRulesStates()
    }

    private func removeAppDisableRule(features: DisableableFeature, app: AppDisableRule) {
        self.featureDisableRules.removeAll { rule in
            guard let ruleApp = rule.app, ruleApp == app else { return false }
            return rule.features.intersection(features) != []
        }
        self.refreshDisableRulesStates()
    }

    private func removeGlobalRulesForFeatures(_ features: DisableableFeature) {
        self.featureDisableRules.removeAll { rule in
            guard rule.app == nil else { return false }
            return rule.features.intersection(features) != []
        }
    }

    private func removeDuplicateAppDisableRules(newRule: FeatureDisableRule, features: DisableableFeature) {
        guard let newApp = newRule.app else { return }

        self.featureDisableRules.removeAll { existingRule in
            guard let existingApp = existingRule.app, existingApp == newApp else { return false }
            return existingRule.features.intersection(features) != []
        }
    }
}
