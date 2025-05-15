import Foundation
import Defaults

extension OnitPanelState {
    
    @MainActor
    func performWebSearch(query: String) async -> [WebSearchResult] {
        @Default(.useOnitChat) var useOnitChat
        @Default(.tavilyAPIToken) var tavilyAPIToken
        do {
            if useOnitChat {
                let client = FetchingClient()
                let response = try await client.getChatSearch(query: query)
                return response.results
            } else if !tavilyAPIToken.isEmpty {
                let (_, results) = try await TavilyService.search(
                    query: query,
                    apiKey: tavilyAPIToken,
                    maxResults: 5
                )
                webSearchError = nil
                return results
            } else {
                return []
            }
        } catch {
            print("Web search error: \(error)")
            webSearchError = error
            return []
        }
    }
}
