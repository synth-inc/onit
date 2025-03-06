//
//  TypeaheadTestResult.swift
//  Onit
//
//  Created by Kévin Naudin on 04/03/2025.
//

struct TypeaheadTestResult: Codable {
    let testId: String
    let success: Bool
    let metrics: [String: String]
    let error: String?
    
    struct Metric {
        
        static let elapsedTime = "elapsed_time"
        static let tokenPerSecond = "token_per_second"
        
        static let completionLength = "completion_length"
        static let similarityScore = "similarity_score"
        static let contextRelevance = "context_relevance"
        
        static let contextLength = "context_length"
        static let precedingTextLength = "preceding_text_length"
        static let followingTextLength = "following_text_length"
    }
}
