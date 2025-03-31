import Foundation

struct WebSearchResult: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var url: String
    var content: String
    var score: Double
    
    init(title: String, url: String, content: String, score: Double) {
        self.title = title
        self.url = url
        self.content = content
        self.score = score
    }
    
    // Initialize from Tavily API response
    init(from tavilyResult: [String: Any]) {
        self.title = tavilyResult["title"] as? String ?? "Unknown Title"
        self.url = tavilyResult["url"] as? String ?? ""
        self.content = tavilyResult["content"] as? String ?? ""
        self.score = tavilyResult["score"] as? Double ?? 0.0
    }
    
    // Convert to Context
    func toContext() -> Context {
        return Context(
            type: .web,
            title: title,
            content: content,
            url: URL(string: url),
            source: "Tavily Web Search"
        )
    }
}