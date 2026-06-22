//
//  FeatureDisableManager+SchedulingExpirationDate.swift
//  Onit
//
//  Created by Kévin Naudin on 27/01/2026.
//

import Foundation

extension FeatureDisableManager {
    // MARK: - Expiration Date Handling

    func removeExpiredDisableRules() {
        let now = Date()

        self.featureDisableRules.removeAll { rule in
            guard let expirationDate = rule.expirationDate else { return false }
            return expirationDate <= now
        }
    }

    func removeExpiredIgnoredDisableRules() {
        let now = Date()

        self.ignoredFeatureDisableRules.removeAll { rule in
            rule.ignoredUntil <= now
        }
    }

    func getNextClosestExpirationDate() -> Date? {
        let now = Date()
        let expirationDates = featureDisableRules.compactMap { $0.expirationDate }

        return expirationDates
            .filter { $0 > now }
            .min()
    }

    func getNextClosestIgnoredUntilDate() -> Date? {
        let now = Date()

        return self.ignoredFeatureDisableRules
            .map { $0.ignoredUntil }
            .filter { $0 > now }
            .min()
    }
}
