//
//  ModelHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 4/3/25.
//

import Defaults

@MainActor
func getModelToken(provider: AIModel.ModelProvider) -> String? {
    switch provider {
    case .openAI:
        return Defaults[.openAIToken]
    case .anthropic:
        return Defaults[.anthropicToken]
    case .xAI:
        return Defaults[.xAIToken]
    case .googleAI:
        return Defaults[.googleAIToken]
    case .deepSeek:
        return Defaults[.deepSeekToken]
    case .perplexity:
        return Defaults[.perplexityToken]
    case .custom:
        return nil
    }
}
