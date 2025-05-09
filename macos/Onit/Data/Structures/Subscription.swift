//
//  Subscription.swift
//  Onit
//
//  Created by Jason Swanson on 4/29/25.
//

struct SubscriptionStatus {
    static let incomplete = "Incomplete"
    static let incompleteExpired = "Incomplete Expired"
    static let trialing = "Pro 2-week trial"
    static let active = "Pro"
    static let pastDue = "Past Due"
    static let canceled = "Pro plan expiring soon"
    static let unpaid = "Unpaid"
    static let paused = "Paused"
    static let free = "Free Plan"
}

struct Subscription: Codable {
    let id: String
    let status: String
    let statusMessage: String?
    let trialEnd: Double? // Second since the epoch
    let currentPeriodStart: Double // Second since the epoch
    let currentPeriodEnd: Double // Second since the epoch
    let cancelAtPeriodEnd: Bool
}

struct ChatUsage: Codable {
    let usage: Double
    let quota: Double
    let paid: Bool
    let currentPeriodStart: Double // Second since the epoch
    let currentPeriodEnd: Double // Second since the epoch
}
