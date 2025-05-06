//
//  SubscriptionFeature.swift
//  Onit
//
//  Created by Jason Swanson on 5/6/25.
//

import Foundation

struct SubscriptionFeature: Codable, Identifiable {
    let name: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case name
        case description
    }

    let id = UUID()
}
