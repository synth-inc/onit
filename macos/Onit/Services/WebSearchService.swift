import Foundation
import Combine

struct WebSearchResult: Codable {
    let message: String
    let sources: [WebSearchSource]
}

struct WebSearchSource: Codable {
    let pageContent: String
    let metadata: WebSearchMetadata
}

struct WebSearchMetadata: Codable {
    let title: String
    let url: String
}

enum WebSearchError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL for web search"
        case .requestFailed(let error):
            return "Web search request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from web search"
        case .decodingFailed(let error):
            return "Failed to decode web search results: \(error.localizedDescription)"
        }
    }
}

class WebSearchService {
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: String = "http://localhost:3000", session: URLSession = .shared) {
        self.baseURL = URL(string: baseURL)!
        self.session = session
    }
    
    func search(query: String, history: [[String]]) async throws -> WebSearchResult {
        guard let url = URL(string: "/api/search", relativeTo: baseURL) else {
            throw WebSearchError.invalidURL
        }
        
        // Create the request body
        let requestBody: [String: Any] = [
            "chatModel": [
                "provider": "openai",
                "name": "gpt-4o-mini"
            ],
            "embeddingModel": [
                "provider": "openai",
                "name": "text-embedding-3-large"
            ],
            "optimizationMode": "balanced",
            "focusMode": "webSearch",
            "query": query,
            "history": history
        ]
        
        // Convert the request body to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send the request
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check the response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw WebSearchError.invalidResponse
            }
            
            // Decode the response
            do {
                let result = try JSONDecoder().decode(WebSearchResult.self, from: data)
                return result
            } catch {
                throw WebSearchError.decodingFailed(error)
            }
        } catch let error as WebSearchError {
            throw error
        } catch {
            throw WebSearchError.requestFailed(error)
        }
    }
}