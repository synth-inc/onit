//
//  ModelValidationEndpoint.swift
//  Onit
//
//  Created by Loyd Kim on 3/14/25.
//

import Foundation

struct ModelValidationEndpoint: Endpoint {
    typealias BaseURL = URL
    typealias Path = String
    typealias AdditionalHeaders = [String: String]?
    
    typealias Request = ValidationRequest
    typealias Response = ValidationResponse
    var getParams: AdditionalHeaders { nil }
    var method: HTTPMethod { .post }
    var timeout: TimeInterval? { nil }
    
    let provider: AIModel.ModelProvider
    let model: String
    let token: String?
    
    var baseURL: BaseURL { handleProviderValues().0 }
    var path: Path { handleProviderValues().1 }
    var additionalHeaders: AdditionalHeaders { handleProviderValues().2 }

    var requestBody: Request? {
        let validationTestMessage = [ValidationMessage(role: "user", content: "hi")]
        
        switch provider {
        case .anthropic:
            return ValidationRequest(model: model, messages: validationTestMessage, maxTokens: 1024)
        case .googleAI:
            return ValidationRequest(model: model, messages: validationTestMessage, stream: false, n: 1)
        default: // e.g. .openAI, .xAI, .deepSeek, .perplexity, .custom
            return ValidationRequest(model: model, messages: validationTestMessage, stream: false)
        }
    }
}

extension ModelValidationEndpoint {
    private func handleProviderValues() -> (BaseURL, Path, AdditionalHeaders) {
        switch provider {
        case .openAI:
            let openAI = OpenAIChatEndpoint(messages: [], token: token, model: model)
            return (openAI.baseURL, openAI.path, openAI.additionalHeaders)
        case .anthropic:
            let anthropic = AnthropicChatEndpoint(model: model, system: "", token: token, messages: [], maxTokens: 0)
            return (anthropic.baseURL, anthropic.path, anthropic.additionalHeaders)
        case .xAI:
            let xAI = XAIChatEndpoint(messages: [], model: model, token: token)
            return (xAI.baseURL, xAI.path, xAI.additionalHeaders)
        case .googleAI:
            let googleAI = GoogleAIChatEndpoint(messages: [], model: model, token: token)
            return (googleAI.baseURL, googleAI.path, googleAI.additionalHeaders)
        case.deepSeek:
            let deepSeek = DeepSeekChatEndpoint(messages: [], model: model, token: token)
            return (deepSeek.baseURL, deepSeek.path, deepSeek.additionalHeaders)
        case .perplexity:
            let perplexity = PerplexityChatEndpoint(messages: [], model: model, token: token)
            return (perplexity.baseURL, perplexity.path, perplexity.additionalHeaders)
        default: // .custom
            fatalError("Custom providers must provide a base URL")
        }
    }
}

struct ValidationMessage: Codable {
    let role: String
    let content: String
}

struct ValidationRequest: Codable {
    let model: String
    let messages: [ValidationMessage]
    let max_tokens: Int?
    let stream: Bool?
    let n: Int?
    
    init(
        model: String,
        messages: [ValidationMessage],
        maxTokens: Int? = nil,
        stream: Bool? = nil,
        n: Int? = nil
    ) {
        self.model = model
        self.messages = messages
        self.max_tokens = maxTokens
        self.stream = stream
        self.n = n
    }
}

// Only used for `Endpoint` protocol conformance.
struct ValidationResponse: Codable {}
