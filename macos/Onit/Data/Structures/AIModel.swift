//
//  GPTModels.swift
//  Onit
//
//  Created by Benjamin Sage on 10/10/24.
//

import Foundation

enum AIModel: String, CaseIterable, Codable {
    // OpenAI Models
    case gpt4 = "gpt-4"
    case gpt4Turbo = "gpt-4-turbo-preview"
    case gpt4Vision = "gpt-4-vision-preview"
    case gpt35Turbo = "gpt-3.5-turbo"
    case gpt35Turbo16k = "gpt-3.5-turbo-16k"
    
    // Anthropic Models
    case claude3Opus = "claude-3-opus-20240229"
    case claude3Sonnet = "claude-3-sonnet-20240229"
    case claude3Haiku = "claude-3-haiku-20240229"
    case claude21 = "claude-2.1"
    case claude20 = "claude-2.0"
    case claudeInstant = "claude-instant-1.2"
    
    // xAI Models
    case grok2 = "grok-2-1212"
    case grok2Vision = "grok-2-vision-1212"
    case grokBeta = "grok-beta"
    case grokBetaVision = "grok-vision-beta"
    
    var provider: ModelProvider {
        switch self {
        case .gpt4, .gpt4Turbo, .gpt4Vision, .gpt35Turbo, .gpt35Turbo16k:
            return .openAI
        case .claude3Opus, .claude3Sonnet, .claude3Haiku, .claude21, .claude20, .claudeInstant:
            return .anthropic
        case .grok2, .grok2Vision, .grokBeta, .grokBetaVision:
            return .xAI
        }
    }
    
    var supportsVision: Bool {
        switch self {
        case .gpt4Vision, .claude3Opus, .claude3Sonnet, .claude3Haiku, .grok2Vision, .grokBetaVision:
            return true
        default:
            return false
        }
    }
    
    
    var displayName: String {
        switch self {
        case .gpt4: return "GPT-4"
        case .gpt4Turbo: return "GPT-4 Turbo"
        case .gpt4Vision: return "GPT-4 Vision"
        case .gpt35Turbo: return "GPT-3.5 Turbo"
        case .gpt35Turbo16k: return "GPT-3.5 Turbo 16K"
        case .claude3Opus: return "Claude 3 Opus"
        case .claude3Sonnet: return "Claude 3 Sonnet"
        case .claude3Haiku: return "Claude 3 Haiku"
        case .claude21: return "Claude 2.1"
        case .claude20: return "Claude 2.0"
        case .claudeInstant: return "Claude Instant"
        case .grok2: return "Grok 2"
        case .grok2Vision: return "Grok 2 Vision"
        case .grokBeta: return "Grok Beta"
        case .grokBetaVision: return "Grok Vision Beta"
        }
    }
    
    enum ModelProvider: String, Codable {
        case openAI = "openai"
        case anthropic = "anthropic"
        case xAI = "xai"

        var title: String {
            switch self {
            case .openAI: return "OpenAI"
            case .anthropic: return "Anthropic"
            case .xAI: return "xAI"
            }
        }

        var sample: String {
            switch self {
            case .openAI: return "GPT-4o"
            case .anthropic: return "Claude"
            case .xAI: return "Grok"
            }
        }

        var url: URL {
            switch self {
            case .openAI:
                URL(string: "https://platform.openai.com/api-keys")!
            case .anthropic:
                URL(string: "https://docs.anthropic.com/en/api/getting-started")!
            case .xAI:
                URL(string: "https://accounts.x.ai/account")!
            }
        }
    }
}

extension AIModel: Identifiable {
    var id: RawValue { self.rawValue }
}
