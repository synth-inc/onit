import Foundation

struct WebSearchResult: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var url: String
    var content: String
    var rawContent: String?
    var score: Double
    
    enum CodingKeys: String, CodingKey {
        case title
        case url
        case content
        case rawContent = "raw_content"
        case score
    }
    
    // Custom initializer for decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // Always generate a new UUID
        self.title = try container.decode(String.self, forKey: .title)
        self.url = try container.decode(String.self, forKey: .url)
        self.content = try container.decode(String.self, forKey: .content)
        self.rawContent = try container.decodeIfPresent(String.self, forKey: .rawContent)
        self.score = try container.decode(Double.self, forKey: .score)
    }
    
    // Initialize from Tavily API response
    init(from tavilyResult: [String: Any]) {
        self.title = tavilyResult["title"] as? String ?? "Unknown Title"
        self.url = tavilyResult["url"] as? String ?? ""
        self.content = tavilyResult["content"] as? String ?? ""
        self.rawContent = tavilyResult["raw_content"] as? String ?? ""
        self.score = tavilyResult["score"] as? Double ?? 0.0
    }
    
    public var fullContent: String {
        return content + " " + (rawContent ?? "")
    }
    
    // Convert to Context
    func toContext() -> Context {
        return Context(
            title: title,
            content: fullContent,
            source: source,
            url: URL(string: url)
        )
    }
    
    private func extractRootDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return ""
        }
        return host
    }
    
    public var source : String {
        return extractRootDomain(from: url)
    }
}
