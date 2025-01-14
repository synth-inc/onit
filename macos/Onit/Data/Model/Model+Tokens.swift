
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
        case xAIToken = "xAIToken"
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
    var xAIToken: String? {
        get {
            UserDefaults.standard.string(forKey: TokenKeys.xAIToken.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: TokenKeys.xAIToken.rawValue)
        }
    }

    private enum TokenValidationKeys: String {
        case openAITokenValidated = "openAITokenValidated"
        case anthropicTokenValidated = "anthropicTokenValidated"
        case xAITokenValidated = "xAITokenValidated"
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
    var isXAITokenValidated: Bool {
        get {
            UserDefaults.standard.bool(forKey: TokenValidationKeys.xAITokenValidated.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: TokenValidationKeys.xAITokenValidated.rawValue)
        }
    }

    private enum UseModelKeys: String {
        case openAITokenValidated = "useOpenAI"
        case anthropicTokenValidated = "useAnthropic"
        case xAITokenValidated = "useXAI"
    }
    var useOpenAI: Bool {
        get {
            UserDefaults.standard.bool(forKey: UseModelKeys.openAITokenValidated.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: UseModelKeys.openAITokenValidated.rawValue)
        }
    }
    var useAnthropic: Bool {
        get {
            UserDefaults.standard.bool(forKey: UseModelKeys.anthropicTokenValidated.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: UseModelKeys.anthropicTokenValidated.rawValue)
        }
    }
    var useXAI: Bool {
        get {
            UserDefaults.standard.bool(forKey: UseModelKeys.xAITokenValidated.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: UseModelKeys.xAITokenValidated.rawValue)
        }
    }
}
