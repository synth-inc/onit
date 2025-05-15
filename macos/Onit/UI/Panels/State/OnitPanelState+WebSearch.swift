import Foundation
import Defaults

extension OnitPanelState {
    
    @MainActor
    func performWebSearch(query: String) async -> [WebSearchResult] {
        @Default(.tavilyAPIToken) var tavilyAPIToken
        @Default(.isTavilyAPITokenValidated) var isTavilyAPITokenValidated
        do {
            if !isTavilyAPITokenValidated, !tavilyAPIToken.isEmpty {
                let client = FetchingClient()
                let response = try await client.getChatSearch(query: query)
                return response.results
            } else {
                let (_, results) = try await TavilyService.search(
                    query: query,
                    apiKey: tavilyAPIToken,
                    maxResults: 5
                )
                webSearchError = nil
                return results
            }
        } catch {
            print("Web search error: \(error)")
            webSearchError = error
            return []
        }
    }
}
