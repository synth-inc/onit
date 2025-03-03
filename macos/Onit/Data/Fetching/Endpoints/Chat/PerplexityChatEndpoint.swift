import Foundation

struct PerplexityChatEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://api.perplexity.ai")!
    
    typealias Request = PerplexityChatRequest
    typealias Response = PerplexityChatResponse
    
    let messages: [PerplexityChatMessage]
    let model: String
    let token: String?
    
    var path: String { "/chat/completions" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var requestBody: PerplexityChatRequest? {
        PerplexityChatRequest(model: model, messages: messages, stream: false)
    }
    var additionalHeaders: [String: String]? { nil }
    var timeout: TimeInterval? { nil }
    
    func getContent(response: Response) -> String? {
        return response.choices.first?.message.content
    }
}

struct PerplexityChatMessage: Codable {
    let role: String
    let content: PerplexityChatContent
}

enum PerplexityChatContent: Codable {
    case text(String)
    case multiContent([PerplexityChatContentPart])
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let str):
            try container.encode(str)
        case .multiContent(let parts):
            try container.encode(parts)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .text(str)
        } else if let parts = try? container.decode([PerplexityChatContentPart].self) {
            self = .multiContent(parts)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid content format for PerplexityChatContent")
        }
    }
}

struct PerplexityChatContentPart: Codable {
    let type: String
    let text: String?
    let image_url: ImageURL?

    struct ImageURL: Codable {
        let url: String
    }
}

struct PerplexityChatRequest: Codable {
    let model: String
    let messages: [PerplexityChatMessage]
    let stream: Bool
}

struct PerplexityChatResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
} 
