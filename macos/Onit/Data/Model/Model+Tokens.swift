
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
        case googleAIToken = "googleAIToken"
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
    var googleAIToken: String? {
        get {
            UserDefaults.standard.string(forKey: TokenKeys.googleAIToken.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: TokenKeys.googleAIToken.rawValue)
        }
    }

    private enum TokenValidationKeys: String {
        case openAITokenValidated = "openAITokenValidated"
        case anthropicTokenValidated = "anthropicTokenValidated"
        case xAITokenValidated = "xAITokenValidated"
        case googleAITokenValidated = "googleAITokenValidated"
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
    var isGoogleAITokenValidated: Bool {
        get {
            UserDefaults.standard.bool(forKey: TokenValidationKeys.googleAITokenValidated.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: TokenValidationKeys.googleAITokenValidated.rawValue)
        }
    }

    private enum UseModelKeys: String {
        case openAITokenValidated = "useOpenAI"
        case anthropicTokenValidated = "useAnthropic"
        case xAITokenValidated = "useXAI"
        case googleAITokenValidated = "useGoogleAI"
        case localModelValidated = "useLocalModel"
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
    var useGoogleAI: Bool {
        get {
            UserDefaults.standard.bool(forKey: UseModelKeys.googleAITokenValidated.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: UseModelKeys.googleAITokenValidated.rawValue)
        }
    }
    var useLocal: Bool {
        get {
            UserDefaults.standard.bool(forKey: UseModelKeys.localModelValidated.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: UseModelKeys.localModelValidated.rawValue)
        }
    }

    var remoteNeedsSetup: Bool {
        !useOpenAI && !useAnthropic && !useXAI && !useGoogleAI
    }

    func clearTokens() {
        // Helpful for debugging the new-user-experience
        UserDefaults.standard.removeObject(forKey: TokenKeys.openAIToken.rawValue)
        UserDefaults.standard.removeObject(forKey: TokenKeys.anthropicToken.rawValue)
        UserDefaults.standard.removeObject(forKey: TokenKeys.xAIToken.rawValue)
        UserDefaults.standard.removeObject(forKey: TokenKeys.googleAIToken.rawValue)
        
        UserDefaults.standard.removeObject(forKey: TokenValidationKeys.openAITokenValidated.rawValue)
        UserDefaults.standard.removeObject(forKey: TokenValidationKeys.anthropicTokenValidated.rawValue)
        UserDefaults.standard.removeObject(forKey: TokenValidationKeys.xAITokenValidated.rawValue)
        UserDefaults.standard.removeObject(forKey: TokenValidationKeys.googleAITokenValidated.rawValue)

        UserDefaults.standard.removeObject(forKey: UseModelKeys.openAITokenValidated.rawValue)
        UserDefaults.standard.removeObject(forKey: UseModelKeys.anthropicTokenValidated.rawValue)
        UserDefaults.standard.removeObject(forKey: UseModelKeys.xAITokenValidated.rawValue)
        UserDefaults.standard.removeObject(forKey: UseModelKeys.googleAITokenValidated.rawValue)
        UserDefaults.standard.removeObject(forKey: UseModelKeys.localModelValidated.rawValue)
    }
}
