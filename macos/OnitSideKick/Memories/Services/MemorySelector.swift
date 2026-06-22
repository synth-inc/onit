//
//  MemorySelector.swift
//  Onit
//
//  Created by Kévin Naudin on 22/12/2025.
//

import Defaults
import Foundation

/// A memory with an associated relevance score
struct ScoredMemory: Identifiable {
    let memory: Memory
    let score: Double
    let matchedKeywords: [String]

    var id: Int64? { memory.id }
}

/// Context information used to select the most relevant memories
struct MemorySelectionContext {
    /// Bundle identifier of the current app
    let appBundleIdentifier: String?

    /// The user's instruction/prompt
    let userInstruction: String

    /// The text selected by the user (if any)
    let selectedText: String?

    /// Text from auto-context (e.g., window content)
    let autoContextText: String?
}

/// Selects the most relevant memories based on context
struct MemorySelector {

    // MARK: - Configuration

    /// Chars per token approximation (1 token ≈ 4 chars)
    static let charsPerToken = 4

    /// Token budget from user settings
    private static var tokenBudget: Int {
        Defaults[.maxMemoryTokens]
    }

    /// Score weights
    private static let appSpecificScore: Double = 3.0
    private static let globalScore: Double = 1.5
    private static let keywordMatchScore: Double = 0.5

    /// Stop words to ignore when extracting keywords
    private static let stopWords: Set<String> = [
        "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
        "i", "you", "we", "they", "it", "this", "that", "these", "those",
        "to", "of", "in", "on", "for", "with", "and", "or", "but", "not",
        "at", "by", "from", "as", "into", "through", "during", "before", "after",
        "above", "below", "between", "under", "again", "further", "then", "once",
        "here", "there", "when", "where", "why", "how", "all", "each", "few",
        "more", "most", "other", "some", "such", "no", "nor", "only", "own",
        "same", "so", "than", "too", "very", "can", "will", "just", "should",
        "now", "do", "does", "did", "done", "doing", "have", "has", "had",
        "my", "your", "his", "her", "its", "our", "their", "what", "which",
        "who", "whom", "would", "could", "might", "must", "shall", "may"
    ]

    // MARK: - Selection

    /// Selects the most relevant memories for the given context
    /// - Parameters:
    ///   - memories: All available memories (already filtered by app)
    ///   - context: The current context for scoring
    /// - Returns: Scored memories sorted by relevance, within token budget
    static func select(
        memories: [Memory],
        context: MemorySelectionContext
    ) -> [ScoredMemory] {
        // 1. Score each memory
        var scored = memories.map { memory in
            ScoredMemory(
                memory: memory,
                score: calculateScore(memory: memory, context: context),
                matchedKeywords: findMatchedKeywords(memory: memory, context: context)
            )
        }

        // 2. Filter out memories with zero score (wrong app)
        scored = scored.filter { $0.score > 0 }

        // 3. Sort by score descending
        scored.sort { $0.score > $1.score }

        // 4. Select within token budget
        var selected: [ScoredMemory] = []
        var usedChars = 0
        let maxChars = tokenBudget * charsPerToken

        for item in scored {
            let memoryChars = item.memory.content.count
            if usedChars + memoryChars <= maxChars {
                selected.append(item)
                usedChars += memoryChars
            }
        }

        return selected
    }

    // MARK: - Scoring

    /// Calculates the relevance score for a memory
    private static func calculateScore(
        memory: Memory,
        context: MemorySelectionContext
    ) -> Double {
        var score: Double = 0

        // 1. App match scoring
        if memory.isGlobal {
            // Global memories are always relevant but less than app-specific
            score += globalScore
        } else if memory.appBundleIdentifier == context.appBundleIdentifier {
            // Exact app match = very relevant
            score += appSpecificScore
        } else {
            // Memory for a different app = exclude
            return 0
        }

        // 2. Keyword match scoring
        let keywords = extractKeywords(from: context)
        let memoryWords = Set(
            memory.content
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
        )

        let matchCount = keywords.filter { keyword in
            memoryWords.contains { word in
                word.contains(keyword) || keyword.contains(word)
            }
        }.count

        score += Double(matchCount) * keywordMatchScore

        return score
    }

    /// Extracts meaningful keywords from the context
    private static func extractKeywords(from context: MemorySelectionContext) -> [String] {
        let allText = [
            context.userInstruction,
            context.selectedText ?? "",
            context.autoContextText ?? ""
        ].joined(separator: " ")

        return allText
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 && !stopWords.contains($0) }
    }

    /// Finds which keywords from the context match the memory
    private static func findMatchedKeywords(
        memory: Memory,
        context: MemorySelectionContext
    ) -> [String] {
        let keywords = extractKeywords(from: context)
        let memoryText = memory.content.lowercased()

        return keywords.filter { memoryText.contains($0) }
    }
}
