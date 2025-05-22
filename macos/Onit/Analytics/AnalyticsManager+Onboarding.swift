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
