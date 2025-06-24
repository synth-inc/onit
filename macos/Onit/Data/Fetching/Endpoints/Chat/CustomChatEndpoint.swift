import Foundation

struct CustomChatEndpoint: Endpoint {
    var baseURL: URL

    typealias Request = CustomChatRequest
    typealias Response = CustomChatResponse

    let messages: [CustomChatMessage]
    let token: String?
    let model: String

    var path: String { "/v1/chat/completions" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var requestBody: CustomChatRequest? {
        CustomChatRequest(model: model, messages: messages, stream: false)
    }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
    var timeout: TimeInterval? { nil }
    
    func getContent(response: Response) -> String? {
        return response.choices.first?.message.content
    }
}

struct CustomChatMessage: Codable {
    let role: String
    let content: CustomChatContent
}

enum CustomChatContent: Codable {
    case text(String)
    case multiContent([CustomChatContentPart])

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
        } else if let parts = try? container.decode([CustomChatContentPart].self) {
            self = .multiContent(parts)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid content format")
        }
    }
}

struct CustomChatContentPart: Codable {
    let type: String
    let text: String?
    let image_url: ImageURL?


    struct ImageURL: Codable {
        let url: String
    }
}

struct CustomChatRequest: Codable {
    let model: String
    let messages: [CustomChatMessage]
    let stream: Bool
}

struct CustomChatResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message

        struct Message: Codable {
            let content: String
        }
    }
}
