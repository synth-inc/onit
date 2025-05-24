import Foundation

struct WebSearchResult: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var url: String
    var content: String
    var rawContent: String
    var score: Double
    
    // Initialize from Tavily API response
    init(from tavilyResult: [String: Any]) {
        self.title = tavilyResult["title"] as? String ?? "Unknown Title"
        self.url = tavilyResult["url"] as? String ?? ""
        self.content = tavilyResult["content"] as? String ?? ""
        self.rawContent = tavilyResult["rawContent"] as? String ?? ""
        self.score = tavilyResult["score"] as? Double ?? 0.0
    }
    
    public var fullContent: String {
        return content + " " + rawContent
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
