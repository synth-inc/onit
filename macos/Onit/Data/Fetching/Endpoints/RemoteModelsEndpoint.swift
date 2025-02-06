import Foundation

struct RemoteModelsEndpoint: Endpoint {
    typealias Request = EmptyRequest
    typealias Response = ModelsResponse

    var baseURL: URL {
        URL(string: "https://syntheticco.blob.core.windows.net")!
    }

    var path: String {
        "/onit/models-deepseek.json"
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

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case provider
        case defaultOn = "default_on"
        case supportsVision = "supports_vision"
        case supportsSystemPrompts = "supports_system_prompt"
    }
}
