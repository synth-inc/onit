import Foundation

struct ModelsEndpoint: Endpoint {
    typealias Request = Never
    typealias Response = ModelsResponse
    
    var baseURL: URL {
        URL(string: "https://api.onit.dev")!
    }
    
    var path: String {
        "/v1/models"
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var token: String? {
        nil
    }
    
    var requestBody: Request? {
        nil
    }
    
    var additionalHeaders: [String : String]? {
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
    let supportsVision: Bool
    let supportsSystemPrompts: Bool
}