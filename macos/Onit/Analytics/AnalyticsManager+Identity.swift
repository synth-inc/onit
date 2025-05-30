//
//  AnalyticsManager+Identity.swift
//  Onit
//
//  Created by Codex AI on 2025-XX-XX.
//

import PostHog
import Foundation

extension AnalyticsManager {
    struct Identity {
        static func identify(account: Account) {
            var properties: [String: Any] = [:]
            if let email = account.email ?? account.appleEmail {
                properties["email"] = email
            }
            PostHogSDK.shared.identify(String(account.id), userProperties: properties)
        }
    }
}

