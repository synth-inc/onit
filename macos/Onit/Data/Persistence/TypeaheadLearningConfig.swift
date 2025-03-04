//
//  TypeaheadLearningConfig.swift
//  Onit
//
//  Created by Kévin Naudin on 03/03/2025.
//

import Defaults
import Foundation

/// Type ahead Learning Configuration
struct TypeaheadLearningConfig: Codable, Defaults.Serializable {
    var isEnabled: Bool
    var hasUserConsent: Bool?
    var lastSyncVersion: String?
    
    static let `default` = TypeaheadLearningConfig(
        isEnabled: false,
        hasUserConsent: nil,
        lastSyncVersion: nil
    )
}

