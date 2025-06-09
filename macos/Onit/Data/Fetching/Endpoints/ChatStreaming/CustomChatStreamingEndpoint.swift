import Foundation
import EventSource

struct CustomChatStreamingEndpoint: StreamingEndpoint {
    var baseURL: URL
    
    typealias Request = CustomChatRequest
    typealias Response = CustomChatStreamingResponse
    
    let messages: [CustomChatMessage]
    let token: String?
    let model: String
    
    var path: String { "/v1/chat/completions" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var requestBody: CustomChatRequest? {
        CustomChatRequest(model: model, messages: messages, stream: true)
    }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
    var timeout: TimeInterval? { nil }
    
    func getContentFromSSE(event: EVEvent) throws -> String? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            return response.choices.first?.delta.content
        }
        
        return nil
    }
    
    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(CustomChatStreamingError.self, from: data)
        
        return response?.error.message
    }
}

struct CustomChatStreamingResponse: Codable {
    let choices: [Choice]
    let created: Int
    let id: String
    let model: String
    let object: String

    struct Choice: Codable {
        let delta: Delta
        let index: Int

        enum CodingKeys: String, CodingKey {
            case delta
            case index
        }
    }

    struct Delta: Codable {
        let content: String?
        let role: String?
    }
}

struct CustomChatStreamingError: Codable {
    let error: ErrorMessage

    struct ErrorMessage: Codable {
        let message: String
    }
}
