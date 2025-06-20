//
//  QuickEditConfig.swift
//  Onit
//
//  Created by Kévin Naudin on 06/20/2025.
//

import Foundation
import Defaults

struct QuickEditConfig: Codable, Defaults.Serializable {
    var isEnabled: Bool
    var excludedApps: Set<String>
    var pausedApps: [String: Date]
    
    static let `default` = QuickEditConfig(
        isEnabled: true,
        excludedApps: [],
        pausedApps: [:]
    )
}