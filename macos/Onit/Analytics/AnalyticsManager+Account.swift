//
//  AnalyticsManager+Account.swift
//  Onit
//
//  Created by Kévin Naudin on 21/05/2025.
//

import PostHog

extension AnalyticsManager {
    struct AccountEvents {
        static func createAccountPressed() {
            AnalyticsManager.sendCommonEvent(event: "account_create")
        }
        
        static func signInPressed() {
            AnalyticsManager.sendCommonEvent(event: "account_sign_in")
        }
        
        static func logoutPressed() {
            AnalyticsManager.sendCommonEvent(event: "account_logout")
        }
        
        static func deletePressed() {
            AnalyticsManager.sendCommonEvent(event: "account_delete")
        }
        
        static func deleteConfirmationCancelPressed() {
            AnalyticsManager.sendCommonEvent(event: "account_delete_confirmation_cancel")
        }
        
        static func deleteConfirmationDeletePressed() {
            AnalyticsManager.sendCommonEvent(event: "account_delete_confirmation_delete")
        }
    }
}
