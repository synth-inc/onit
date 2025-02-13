//
//  TypeaheadConfig.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import Defaults
import Foundation

/// Type ahead Configuration
struct TypeaheadConfig: Codable, Defaults.Serializable {
    var isEnabled: Bool
    var model: String?
    var streamResponse: Bool
    
    var resumeAt: Date?
    var excludedApps: Set<String>
    
    var keepAlive: String?
    var requestTimeout: TimeInterval?
    var options: LocalChatOptions
    
    static let `default` = TypeaheadConfig(
        isEnabled: false,
        model: nil,
        streamResponse: true,
        resumeAt: nil,
        excludedApps: Set(),
        keepAlive: nil,
        requestTimeout: 60.0,
        options: LocalChatOptions(num_ctx: 50, temperature: 0.2, top_p: 0.9, top_k: 40)
    )
}

