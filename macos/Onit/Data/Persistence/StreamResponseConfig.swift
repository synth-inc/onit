//
//  StreamResponseConfig.swift
//  Onit
//
//  Created by Kévin Naudin on 12/02/2025.
//

import Defaults

/// Configuration which enable/disable streaming response
struct StreamResponseConfig: Codable, Defaults.Serializable {
    var openAI: Bool
    var anthropic: Bool
    var xAI: Bool
    var googleAI: Bool
    var deepSeek: Bool
    var perplexity: Bool
    var customProviders: [String: Bool]
    var local: Bool
    
    static let `default` = StreamResponseConfig(
        openAI: true,
        anthropic: true,
        xAI: true,
        googleAI: true,
        deepSeek: true,
        perplexity: false,
        customProviders: [:],
        local: true
    )
}
