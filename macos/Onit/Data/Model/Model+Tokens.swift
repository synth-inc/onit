
//
//  Model+Tokens.swift
//  Onit
//
//  Created by Tim Lenardo on 1/11/25.
//

import Foundation

extension OnitModel {
    private enum TokenKeys: String {
        case openAIToken = "openAIToken"
        case anthropicToken = "anthropicToken"
    }
    var openAIToken: String? {
        get {
            UserDefaults.standard.string(forKey: TokenKeys.openAIToken.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: TokenKeys.openAIToken.rawValue)
        }
    }
    var anthropicToken: String? {
        get {
            UserDefaults.standard.string(forKey: TokenKeys.anthropicToken.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: TokenKeys.anthropicToken.rawValue)
        }
    }

    private enum TokenValidationKeys: String {
        case openAITokenValidated = "openAITokenValidated"
        case anthropicTokenValidated = "anthropicTokenValidated"
    }
    var isOpenAITokenValidated: Bool {
        get {
            UserDefaults.standard.bool(forKey: TokenValidationKeys.openAITokenValidated.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: TokenValidationKeys.openAITokenValidated.rawValue)
        }
    }

    var isAnthropicTokenValidated: Bool {
        get {
            UserDefaults.standard.bool(forKey: TokenValidationKeys.anthropicTokenValidated.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: TokenValidationKeys.anthropicTokenValidated.rawValue)
        }
    }
}
