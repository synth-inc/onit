//
//  FeatureDisableModels.swift
//  Onit
//
//  Created by Kévin Naudin on 27/01/2026.
//

import Defaults
import Foundation

// MARK: - DisableableFeature

/// Features that can be disabled via the unified FeatureDisable system
struct DisableableFeature: OptionSet, Codable, Equatable, Defaults.Serializable {
    let rawValue: Int

    static let sidekick = DisableableFeature(rawValue: 1 << 2)

    static let all: DisableableFeature = [.sidekick]

    /// Features affected by menu actions - configured by developers for testing
    static let menuDefault: DisableableFeature = [.sidekick]
}

// MARK: - AppDisableRule

/// Identifies an application for disable rules
struct AppDisableRule: Codable, Equatable, Defaults.Serializable {
    let name: String
    let bundleId: String?
    let bundleUrl: URL?
    let executableUrl: URL?

    static func == (lhs: AppDisableRule, rhs: AppDisableRule) -> Bool {
        if let lhsBundleId = lhs.bundleId,
           let rhsBundleId = rhs.bundleId
        {
            return lhsBundleId == rhsBundleId
        } else if let lhsBundleUrl = lhs.bundleUrl,
                  let rhsBundleUrl = rhs.bundleUrl
        {
            return lhsBundleUrl == rhsBundleUrl
        } else if let lhsExecutableUrl = lhs.executableUrl,
                  let rhsExecutableUrl = rhs.executableUrl
        {
            return lhsExecutableUrl == rhsExecutableUrl
        } else {
            return lhs.name.caseInsensitiveCompare(rhs.name) == .orderedSame
        }
    }
}

// MARK: - DisableRuleTimeRange

/// Time range for scheduled disable rules
struct DisableRuleTimeRange: Codable, Equatable {
    let startTime: Date
    let endTime: Date
}

// MARK: - FeatureDisableRule

/// Unified disable rule that can apply to one or more features
struct FeatureDisableRule: Codable, Equatable, Defaults.Serializable {
    let id: UUID
    let features: DisableableFeature
    let app: AppDisableRule?
    let expirationDate: Date?
    let timeRange: DisableRuleTimeRange?

    init(
        id: UUID = UUID(),
        features: DisableableFeature,
        app: AppDisableRule? = nil,
        expirationDate: Date? = nil,
        timeRange: DisableRuleTimeRange? = nil
    ) {
        self.id = id
        self.features = features
        self.app = app
        self.expirationDate = expirationDate
        self.timeRange = timeRange
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - IgnoredFeatureDisableRule

/// Represents a disable rule that is temporarily ignored ("Enable Once")
struct IgnoredFeatureDisableRule: Codable, Equatable, Defaults.Serializable {
    let id: UUID
    let disableRuleId: UUID
    let ignoredUntil: Date
    let isEnableOnce: Bool

    init(
        id: UUID = UUID(),
        disableRuleId: UUID,
        ignoredUntil: Date,
        isEnableOnce: Bool = false
    ) {
        self.id = id
        self.disableRuleId = disableRuleId
        self.ignoredUntil = ignoredUntil
        self.isEnableOnce = isEnableOnce
    }
}

// MARK: - FeatureDisableStatus

/// Represents the current disable status for a feature
enum FeatureDisableStatus: Equatable {
    case disabledInPrivateBrowsing
    case disabledGloballyIndefinitely
    case disabledGloballyTemporarily(expirationDate: Date)
    case disabledGloballyTimeRange(startTime: Date, endTime: Date)
    case disabledForAppIndefinitely(app: AppDisableRule)
    case disabledForAppTemporarily(app: AppDisableRule, expirationDate: Date)
    case disabledForAppTimeRange(app: AppDisableRule, startTime: Date, endTime: Date)
    case notDisabled
}
