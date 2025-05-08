//
//  Stripe.swift
//  Onit
//
//  Created by Loyd Kim on 5/7/25.
//

import Foundation
import SwiftUI

struct Stripe {
    static func openSubscriptionForm(_ openURL: OpenURLAction) async -> String? {
        do {
            let client = FetchingClient()
            let response = try await client.createSubscriptionCheckoutSession()
            if let url = URL(string: response.sessionUrl) {
                await openURL(url)
            }
            
            return nil
        } catch {
            print("Error: \(error.localizedDescription)")
            return "Failed to open subscription form."
        }
    }
    
    static func checkFreeTrialAvailable() async -> String {
        do {
            let client = FetchingClient()
            let freeTrialAvailable = try await client.getSubscriptionFreeTrialAvailable()
            
            if freeTrialAvailable {
                return "true"
            } else {
                return "false"
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            return "Failed to check for free trial availability."
        }
    }
}
