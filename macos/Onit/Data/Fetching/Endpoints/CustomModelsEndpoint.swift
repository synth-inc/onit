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
    let object: String
    let data: [CustomModelInfo]
}

struct CustomModelInfo: Codable {
    let id: String
    let object: String
    let created: Int
    let owned_by: String
}