import Foundation

struct CustomChatEndpoint: Endpoint {
    var baseURL: URL
    
    typealias Request = OpenAIChatRequest
    typealias Response = OpenAIChatResponse
    
    let messages: [OpenAIChatMessage]
    let token: String?
    let model: String
    
    var path: String { "/v1/chat/completions" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var requestBody: OpenAIChatRequest? {
        OpenAIChatRequest(model: model, messages: messages)
    }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
    var timeout: TimeInterval? { nil }
}
