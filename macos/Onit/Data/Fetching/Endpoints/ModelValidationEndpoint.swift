//
//  ModelValidationEndpoint.swift
//  Onit
//
//  Created by Loyd Kim on 3/14/25.
//

import Foundation

struct ModelValidationEndpoint: Endpoint {
    var baseURL: URL {
        switch provider {
        case .openAI:
            return URL(string: "https://api.openai.com")!
        case .anthropic:
            return URL(string: "https://api.anthropic.com")!
        case .xAI:
            return URL(string: "https://api.x.ai")!
        case .googleAI:
            return URL(string: "https://generativelanguage.googleapis.com")!
        case .deepSeek:
            return URL(string: "https://api.deepseek.com")!
        case .perplexity:
            return URL(string: "https://api.perplexity.ai")!
        default: // e.g. .custom
            fatalError("Custom providers must provide a base URL")
        }
    }

    typealias Request = ValidationRequest
    typealias Response = ValidationResponse
    
    let model: String
    let token: String?
    let provider: AIModel.ModelProvider
    
    var path: String {
        switch provider {
        case .openAI: return "/v1/chat/completions"
        case .anthropic: return "/v1/messages"
        case .xAI: return "/v1/chat/completions"
        case .googleAI: return "/v1beta:chatCompletions"
        case .deepSeek: return "/v1/chat/completions"
        case .perplexity: return "/chat/completions"
        default: return "/v1/chat/completions" // e.g. .custom
        }
    }
    
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    
    var requestBody: ValidationRequest? {
        // This is only used to validate the validity of added models in CustomModelFormView
        //   so it's preferred to keep the validation message simple.
        let messages = [ValidationMessage(role: "user", content: "hi")]
        
        switch provider {
        case .anthropic:
            return ValidationRequest(model: model, messages: messages, maxTokens: 1024)
        case .googleAI:
            return ValidationRequest(model: model, messages: messages, stream: false, n: 1)
        default: // e.g. .openAI, .xAI, .deepSeek, .perplexity, .custom
            return ValidationRequest(model: model, messages: messages, stream: false)
        }
    }
    
    var additionalHeaders: [String: String]? {
        // Return nil if token is missing to fail early
        guard let token = token else { return nil }
        
        var headers = [String: String]()
        
        switch provider {
        case .anthropic:
            headers["x-api-key"] = token
            headers["anthropic-version"] = "2023-06-01"
        default: // .openAI, .xAI, .googleAI, .deepSeek, .perplexity, .custom
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    var timeout: TimeInterval? { nil }
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

struct ValidationResponse: Codable {
    // Empty response since we only care about success/failure
}
