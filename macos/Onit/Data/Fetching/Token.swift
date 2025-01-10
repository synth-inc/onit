//
//  Token.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

class Token {
    static var openAIToken: String? = nil
    static var anthropicToken: String? = nil
    
    static func loadTokens() {
        // TODO: Load tokens from secure storage
        // For now, they should be set through settings
    }
}
