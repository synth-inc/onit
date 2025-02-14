//
//  TypeAheadConfig.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import Defaults
import Foundation

/// Type ahead Configuration
struct TypeAheadConfig: Codable, Defaults.Serializable {
    var isEnabled: Bool
    var model: String?
    var streamResponse: Bool
    
    var keepAlive: String?
    var requestTimeout: TimeInterval?
    var options: LocalChatOptions
    
    static let `default` = TypeAheadConfig(
        isEnabled: false,
        model: nil,
        streamResponse: true,
        keepAlive: nil,
        requestTimeout: 60.0,
        options: LocalChatOptions(num_ctx: 50, temperature: 0.1, top_p: 0.9, top_k: nil)
    )
}

