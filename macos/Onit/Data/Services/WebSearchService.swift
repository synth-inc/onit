//
//  WebSearchService.swift
//  Onit
//
//  Created by OpenHands on 11/1/24.
//

import Foundation

class WebSearchService {
    private let searchAPIBaseURL = "https://api.duckduckgo.com/?q="
    private let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    
    enum WebSearchError: Error {
        case invalidURL
        case networkError(Error)
        case parsingError(Error)
        case noResults
    }
    
    func search(query: String) async throws -> [Context] {
        // Use DuckDuckGo API to get search results
        let searchResults = try await performDuckDuckGoSearch(query: query)
        
        var contexts: [Context] = []
        
        // Create contexts from search results
        for result in searchResults.prefix(3) { // Limit to top 3 results
            contexts.append(.webSearch(result.title, result.content))
        }
        
        if contexts.isEmpty {
            throw WebSearchError.noResults
        }
        
        return contexts
    }
    
    private func performDuckDuckGoSearch(query: String) async throws -> [(title: String, content: String, url: URL)] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(searchAPIBaseURL)\(encodedQuery)&format=json") else {
            throw WebSearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try parseDuckDuckGoResults(data: data)
        } catch {
            throw WebSearchError.networkError(error)
        }
    }
    
    private func parseDuckDuckGoResults(data: Data) throws -> [(title: String, content: String, url: URL)] {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["Results"] as? [[String: Any]] else {
                throw WebSearchError.parsingError(NSError(domain: "WebSearchService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"]))
            }
            
            var searchResults: [(title: String, content: String, url: URL)] = []
            
            for result in results {
                if let title = result["Title"] as? String,
                   let content = result["Abstract"] as? String,
                   let urlString = result["FirstURL"] as? String,
                   let url = URL(string: urlString) {
                    searchResults.append((title: title, content: content, url: url))
                }
            }
            
            // If no results in the "Results" array, try the "RelatedTopics" array
            if searchResults.isEmpty, let relatedTopics = json["RelatedTopics"] as? [[String: Any]] {
                for topic in relatedTopics {
                    if let title = topic["Text"] as? String,
                       let urlDict = topic["FirstURL"] as? String,
                       let url = URL(string: urlDict) {
                        // For related topics, we don't have separate content, so use the title
                        searchResults.append((title: title, content: title, url: url))
                    }
                }
            }
            
            // If still no results, use the abstract text if available
            if searchResults.isEmpty, let abstractText = json["AbstractText"] as? String, !abstractText.isEmpty,
               let abstractURL = json["AbstractURL"] as? String, let url = URL(string: abstractURL) {
                searchResults.append((title: json["Heading"] as? String ?? query, content: abstractText, url: url))
            }
            
            return searchResults
        } catch {
            throw WebSearchError.parsingError(error)
        }
    }
    
    // Fallback method if DuckDuckGo API doesn't work - use a simulated search result
    func simulateSearchResults(query: String) -> [Context] {
        let simulatedContent = """
        This is simulated web search content for the query: "\(query)".
        
        The web search functionality would typically fetch real results from search engines and websites,
        but for demonstration purposes, we're showing this placeholder content.
        
        In a real implementation, this would contain actual content from websites relevant to your query.
        """
        
        return [
            .webSearch("Web Search Result for: \(query)", simulatedContent)
        ]
    }
}