//
//  GPTModels.swift
//  Onit
//
//  Created by Benjamin Sage on 10/10/24.
//

import Foundation

struct AIModel: Codable, Identifiable, Hashable {
    let id: String
    let displayName: String
    let provider: ModelProvider
    let defaultOn: Bool
    let supportsVision: Bool
    let supportsSystemPrompts: Bool
    var isNew: Bool = false
    var isDeprecated: Bool = false

    init?(from modelInfo: ModelInfo) {
        guard let provider = ModelProvider(rawValue: modelInfo.provider.lowercased()) else {
            return nil
        }
        self.id = modelInfo.id
        self.displayName = modelInfo.displayName
        self.provider = provider
        self.defaultOn = modelInfo.defaultOn
        self.supportsVision = modelInfo.supportsVision
        self.supportsSystemPrompts = modelInfo.supportsSystemPrompts
    }
    
    static func fetchModels() async throws -> [AIModel] {
        let client = FetchingClient()
        let endpoint = RemoteModelsEndpoint()
        let response = try await client.execute(endpoint)
        return response.models.compactMap { AIModel(from: $0) }
    }
    
    enum ModelProvider: String, Codable, Equatable, Hashable {
        case openAI = "openai"
        case anthropic = "anthropic"
        case xAI = "xai"
        case googleAI = "googleai"

        var title: String {
            switch self {
            case .openAI: return "OpenAI"
            case .anthropic: return "Anthropic"
            case .xAI: return "xAI"
            case .googleAI: return "Google AI"
            }
        }

        var sample: String {
            switch self {
            case .openAI: return "GPT-4o"
            case .anthropic: return "Claude"
            case .xAI: return "Grok"
            case .googleAI: return "Gemini"
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
            case .googleAI:
                return URL(string: "https://makersuite.google.com/app/apikey")!
            }
        }
    }
}
