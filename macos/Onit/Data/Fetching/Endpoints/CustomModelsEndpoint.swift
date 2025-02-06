import Foundation

struct CustomModelsEndpoint: Endpoint {
    typealias Request = EmptyRequest
    typealias Response = CustomModelsResponse
    
    var baseURL: URL
    let token: String?
    
    var path: String { "/v1/models" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .get }
    var requestBody: EmptyRequest? { nil }
    
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
}

struct CustomModelsResponse: Codable {
    let object: String?
    let data: [CustomModelInfo]
}

struct CustomModelInfo: Codable {
    let id: String

    // These are the OpenRouter fields
    let name: String?
    let created: Int?
    let description: String?
    let context_length: Int?
    let architecture: Architecture?
    let pricing: Pricing?
    let top_provider: TopProvider?
    let per_request_limits: PerRequestLimits?

    // These are the Groq fields
    let context_window: Int?
    let object: String?
    let owned_by: String?
    let active: Bool?

    // 'id' is the only mutual field, so it's the only thing we can require...
}

struct Architecture: Codable {
    let modality: String?
    let tokenizer: String?
    let instruct_type: String?
}

struct Pricing: Codable {
    let prompt: String?
    let completion: String?
    let image: String?
    let request: String?
}

struct TopProvider: Codable {
    let context_length: Int?
    let max_completion_tokens: Int?
    let is_moderated: Bool?
}

struct PerRequestLimits: Codable {
    // Define fields if necessary
}
