import Foundation
import Defaults

extension OnitModel {
    @MainActor
    func performWebSearch(query: String) async -> [WebSearchResult] {
        @Default(.tavilyAPIToken) var tavilyAPIToken
        guard !tavilyAPIToken.isEmpty else { return [] }
        do {
            let (_, results) = try await TavilyService.search(
                query: query,
                apiKey: tavilyAPIToken,
                maxResults: 5
            )
            webSearchError = nil
            return results
        } catch {
            print("Web search error: \(error)")
            webSearchError = error
            return []
        }
    }
}