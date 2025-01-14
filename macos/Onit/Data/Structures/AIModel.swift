//
//  GPTModels.swift
//  Onit
//
//  Created by Benjamin Sage on 10/10/24.
//

import Foundation

enum AIModel: String, CaseIterable, Codable {
    // OpenAI Models
    case gpt4o = "gpt-4o"
    case chatgpt4oLatest = "chatgpt-4o-latest"
    case gpt4oMini = "gpt-4o-mini"
    case o1 = "o1"
    case o1Mini = "o1-mini"
    case o1Preview = "o1-preview"
    
    // These are not chat models
//    case gpt4oRealtimePreview = "gpt-4o-realtime-preview"
//    case gpt4oMiniRealtimePreview = "gpt-4o-mini-realtime-preview"
    
    // Anthropic Models
    case claude35SonnetLatest = "claude-3-5-sonnet-latest"
    case claude35HaikuLatest = "claude-3-5-haiku-latest"
    case claude3OpusLatest = "claude-3-opus-latest"
    case claude3Sonnet = "claude-3-sonnet-20240229"
    case claude3Haiku = "claude-3-haiku-20240307"
    
    // xAI Models
    case grok2 = "grok-2-1212"
    case grok2Vision = "grok-2-vision-1212"
    case grokBeta = "grok-beta"
    case grokBetaVision = "grok-vision-beta"
    
    var provider: ModelProvider {
        switch self {
        case .gpt4o, .chatgpt4oLatest, .gpt4oMini, .o1, .o1Mini, .o1Preview:
            return .openAI
        case .claude35SonnetLatest, .claude35HaikuLatest, .claude3OpusLatest, .claude3Sonnet, .claude3Haiku:
            return .anthropic
        case .grok2, .grok2Vision, .grokBeta, .grokBetaVision:
            return .xAI
        }
    }
    
    var supportsVision: Bool {
        switch self {
        case .gpt4o, .chatgpt4oLatest, .gpt4oMini, .o1, .o1Mini, .o1Preview, .grok2Vision, .grokBetaVision, .claude35SonnetLatest, .claude3OpusLatest, .claude3Sonnet, .claude3Haiku:
            return true
        default:
            return false
        }
    }
    
    var supportsSystemPrompts: Bool {
        switch self {
        case .o1, .o1Mini, .o1Preview:
            return false
        default :
            return true
        }
    }
    
    var displayName: String {
        switch self {
        case .gpt4o: return "GPT-4o"
        case .chatgpt4oLatest: return "ChatGPT-4o Latest"
        case .gpt4oMini: return "GPT-4o Mini"
        case .o1: return "O1"
        case .o1Mini: return "O1 Mini"
        case .o1Preview: return "O1 Preview"
            
        case .claude35SonnetLatest: return "Claude 3.5 Sonnet Latest"
        case .claude35HaikuLatest: return "Claude 3.5 Haiku Latest"
        case .claude3OpusLatest: return "Claude 3 Opus Latest"
        case .claude3Sonnet: return "Claude 3 Sonnet"
        case .claude3Haiku: return "Claude 3 Haiku"
            
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
                return URL(string: "https://platform.openai.com/api-keys")!
            case .anthropic:
                return URL(string: "https://docs.anthropic.com/en/api/getting-started")!
            case .xAI:
                return URL(string: "https://accounts.x.ai/account")!
            }
        }
    }
}

extension AIModel: Identifiable {
    var id: RawValue { self.rawValue }
}
