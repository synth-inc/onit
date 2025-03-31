import Foundation
import Defaults

extension OnitModel {
    @MainActor
    func performWebSearch(query: String) async -> [WebSearchResult] {
        @Default(.tavilyAPIToken) var tavilyAPIToken
        
        guard !tavilyAPIToken.isEmpty else { return [] }
        
        isSearchingWeb = true
        
        do {
            let (_, results) = try await TavilyService.search(
                query: query,
                apiKey: tavilyAPIToken,
                maxResults: 5
            )
            
            isSearchingWeb = false
            webSearchResults = results
            return results
        } catch {
            print("Web search error: \(error)")
            isSearchingWeb = false
            return []
        }
    }
    
    @MainActor
    func createAndSavePromptWithWebSearch() {
        let prompt = createPrompt()
        generatingPrompt = prompt
        
        let query = pendingInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            let results = await performWebSearch(query: query)
            
            // Add web search results as context
            let webContexts = results.map { $0.toContext() }
            prompt.contextList.append(contentsOf: webContexts)
            
            // Generate response with the web contexts
            generate(prompt)
            
            // Reset the input
            pendingInstruction = ""
            pendingInput = nil
            pendingContextList = []
        }
    }
}