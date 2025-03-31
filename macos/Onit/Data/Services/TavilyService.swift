import Foundation

class TavilyService {
    private static let baseURL = "https://api.tavily.com"
    
    static func validateAPIKey(_ apiKey: String) async throws -> Bool {
        // Simple validation query
        let testQuery = "test query for validation"
        
        do {
            _ = try await search(query: testQuery, apiKey: apiKey, maxResults: 1)
            return true
        } catch {
            print("Tavily API key validation failed: \(error)")
            return false
        }
    }
    
    static func search(query: String, apiKey: String, maxResults: Int = 5) async throws -> (answer: String?, results: [WebSearchResult]) {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "TavilyService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API key is required"])
        }
        
        let endpoint = "\(baseURL)/search"
        
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "TavilyService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "query": query,
            "search_depth": "advanced",
            "include_answer": true,
            "max_results": maxResults
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            throw NSError(domain: "TavilyService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request body"])
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TavilyService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "TavilyService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(errorMessage)"])
        }
        
        do {
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NSError(domain: "TavilyService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
            }
            
            let answer = jsonResponse["answer"] as? String
            
            var results: [WebSearchResult] = []
            if let resultsArray = jsonResponse["results"] as? [[String: Any]] {
                results = resultsArray.map { WebSearchResult(from: $0) }
            }
            
            return (answer, results)
        } catch {
            throw NSError(domain: "TavilyService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response: \(error.localizedDescription)"])
        }
    }
}