//
//  GPTModels.swift
//  Onit
//
//  Created by Benjamin Sage on 10/10/24.
//

import Defaults
import Foundation

struct AIModel: Codable, Identifiable, Hashable, Defaults.Serializable {
    let id: String
    let displayName: String
    let provider: ModelProvider
    let defaultOn: Bool
    let supportsVision: Bool
    let supportsSystemPrompts: Bool
    var isNew: Bool = false
    var isDeprecated: Bool = false
    var customProviderName: String?

    var uniqueId: String {
        if provider == .custom, let providerName = customProviderName {
            return "\(providerName)-\(id)"
        }
        return "\(provider)-\(id)"
    }

    // Helper method to check if a legacy ID matches this model
    func matchesLegacyId(_ legacyId: String) -> Bool {
        return id == legacyId
    }

    // Helper method to migrate legacy IDs to unique IDs
    static func migrateVisibleModelIds(models: [AIModel], legacyIds: Set<String>) -> Set<String> {
        var newIds = Set<String>()

        // For each legacy ID, find all matching models and add their unique IDs
        for legacyId in legacyIds {
            let matchingModels = models.filter { $0.matchesLegacyId(legacyId) }
            newIds.formUnion(matchingModels.map { $0.uniqueId })
        }

        return newIds
    }

    init(from customModel: CustomModelInfo, providerName: String) {
        self.id = customModel.id
        self.displayName = customModel.id
        self.provider = .custom
        self.defaultOn = false
        self.supportsVision = false
        self.supportsSystemPrompts = true
        self.customProviderName = providerName
    }

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

    @MainActor
    static func fetchModels() async throws -> [AIModel] {
        let client = FetchingClient()
        let endpoint = RemoteModelsEndpoint()
        let response = try await client.execute(endpoint)
        let remoteModels = response.models.compactMap { AIModel(from: $0) }

        var customModels: [AIModel] = []
        for provider in Defaults[.availableCustomProviders] {
            do {
                try await provider.fetchModels()
                customModels.append(contentsOf: provider.models)
            } catch {
                print("Error fetching custom models for provider \(provider.name): \(error)")
            }
        }

        return remoteModels + customModels
    }

    enum ModelProvider: String, Codable, CaseIterable, Equatable, Hashable, Defaults.Serializable {
        case openAI = "openai"
        case anthropic = "anthropic"
        case xAI = "xai"
        case googleAI = "googleai"
        case deepSeek = "deepseek"
        case perplexity = "perplexity"
        case custom = "custom"
    
        var title: String {
            switch self {
            case .openAI: return "OpenAI"
            case .anthropic: return "Anthropic"
            case .xAI: return "xAI"
            case .googleAI: return "Google AI"
            case .deepSeek: return "DeepSeek"
            case .perplexity: return "Perplexity"
            case .custom: return "Custom Providers" 
            }
        }

        var sample: String {
            switch self {
            case .openAI: return "GPT-4o"
            case .anthropic: return "Claude"
            case .xAI: return "Grok"
            case .googleAI: return "Gemini"
            case .deepSeek: return "DeepSeek R1"
            case .perplexity: return "Sonar"
            case .custom: return "Custom Model"
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
            case .deepSeek:
                return URL(string: "https://platform.deepseek.com/api_keys")!
            case .perplexity:
                return URL(string: "https://www.perplexity.ai/settings/api")!
            case .custom:
                return URL(string: "about:blank")!
            }
        }
        
        static func hasValidRemoteToken(provider: Self) -> Bool {
            switch provider {
            case .openAI:
                guard let token = Defaults[.openAIToken] else { return false }
                return !token.isEmpty && Defaults[.isOpenAITokenValidated]
            case .anthropic:
                guard let token = Defaults[.anthropicToken] else { return false }
                return !token.isEmpty && Defaults[.isAnthropicTokenValidated]
            case .xAI:
                guard let token = Defaults[.xAIToken] else { return false }
                return !token.isEmpty && Defaults[.isXAITokenValidated]
            case .googleAI:
                guard let token = Defaults[.googleAIToken] else { return false }
                return !token.isEmpty && Defaults[.isGoogleAITokenValidated]
            case .deepSeek:
                guard let token = Defaults[.deepSeekToken] else { return false }
                return !token.isEmpty && Defaults[.isDeepSeekTokenValidated]
            case .perplexity:
                guard let token = Defaults[.perplexityToken] else { return false }
                return !token.isEmpty && Defaults[.isPerplexityTokenValidated]
            case .custom:
                return false /// When checking for valid tokens on custom providers, use `hasValidCustomToken()` below.
            }
        }
        
        static func hasValidCustomToken(name: String) -> Bool {
            if let customProvider = Defaults[.availableCustomProviders].first(where: { $0.name == name }) {
                return !customProvider.token.isEmpty && customProvider.isTokenValidated
            } else {
                return false
            }
        }
        
        static var userHasRemoteAPITokens: Bool {
            Self.hasValidRemoteToken(provider: .openAI) ||
            Self.hasValidRemoteToken(provider: .anthropic) ||
            Self.hasValidRemoteToken(provider: .xAI) ||
            Self.hasValidRemoteToken(provider: .googleAI) ||
            Self.hasValidRemoteToken(provider: .deepSeek) ||
            Self.hasValidRemoteToken(provider: .perplexity)
        }
    }
}
