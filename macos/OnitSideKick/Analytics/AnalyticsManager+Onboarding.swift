//
//  AnalyticsManager+Onboarding.swift
//  Onit
//
//  Created by Kévin Naudin on 22/05/2025.
//

import PostHog

extension AnalyticsManager {
    struct Onboarding {
        static func opened() {
            AnalyticsManager.sendCommonEvent(event: "onboarding_opened")
        }

        /// Tracks when the onboarding window is closed/dismissed
        /// - Parameters:
        ///   - step: The step the user was on when they dismissed
        ///   - completed: Whether onboarding was completed
        static func dismissed(step: String, completed: Bool) {
            var properties = AnalyticsManager.getCommonProperties()
            properties["step"] = step
            properties["completed"] = completed

            PostHogSDK.shared.capture("onboarding_dismissed", properties: properties)
        }

        static func grandAccessPressed() {
            AnalyticsManager.sendCommonEvent(event: "onboarding_grand_access")
        }

        static func useWithoutAccessibilityPressed() {
            AnalyticsManager.sendCommonEvent(event: "onboarding_continue_without_accessibility")
        }

        struct LimitedExperience {
            static func opened() {
                AnalyticsManager.sendCommonEvent(event: "onboarding_limited_experience_opened")
            }

            static func closePressed() {
                AnalyticsManager.sendCommonEvent(event: "onboarding_limited_experience_close")
            }

            static func continuePressed() {
                AnalyticsManager.sendCommonEvent(event: "onboarding_limited_experience_continue")
            }
        }
    }
}
