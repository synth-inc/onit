import Foundation

struct RemoteModelsEndpoint: Endpoint {
    typealias Request = EmptyRequest
    typealias Response = ModelsResponse

    var baseURL: URL { OnitServer.baseURL }

    var path: String {
        "/supported-models.json"
    }
    var getParams: [String: String]? { nil }

    var method: HTTPMethod { .get }
    var token: String? { nil }
    var timeout: TimeInterval? { nil }
    var requestBody: EmptyRequest?

    var additionalHeaders: [String: String]? {
        nil
    }
}

struct ModelsResponse: Codable {
    let models: [ModelInfo]
}
struct ModelInfo: Codable {
    let id: String
    let displayName: String
    let provider: String
    let defaultOn: Bool
    let supportsVision: Bool
    let supportsSystemPrompts: Bool
    let supportsToolCalling: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case provider
        case defaultOn = "default_on"
        case supportsVision = "supports_vision"
        case supportsSystemPrompts = "supports_system_prompt"
        case supportsToolCalling = "supports_tool_calling"
    }
}
