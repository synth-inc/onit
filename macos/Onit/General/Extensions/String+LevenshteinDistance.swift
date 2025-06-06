//
//  String+LevenshteinDistance.swift
//  Onit
//
//  Created by Alex Carmack on 2024.
//

import Foundation

extension String {
    /// Calculates the Levenshtein distance between this string and another string.
    /// The Levenshtein distance is the minimum number of single-character edits
    /// (insertions, deletions, or substitutions) required to change one string into another.
    ///
    /// - Parameter other: The string to compare against
    /// - Returns: The Levenshtein distance as an integer
    func levenshteinDistance(to other: String) -> Int {
        let selfArray = Array(self)
        let otherArray = Array(other)
        let selfCount = selfArray.count
        let otherCount = otherArray.count
        
        // Handle edge cases
        if selfCount == 0 { return otherCount }
        if otherCount == 0 { return selfCount }
        if self == other { return 0 }
        
        // Create a matrix to store distances
        var matrix = Array(repeating: Array(repeating: 0, count: otherCount + 1), count: selfCount + 1)
        
        // Initialize first row and column
        for i in 0...selfCount {
            matrix[i][0] = i
        }
        for j in 0...otherCount {
            matrix[0][j] = j
        }
        
        // Fill the matrix
        for i in 1...selfCount {
            for j in 1...otherCount {
                let cost = selfArray[i - 1] == otherArray[j - 1] ? 0 : 1
                
                let deletion = matrix[i - 1][j] + 1
                let insertion = matrix[i][j - 1] + 1
                let substitution = matrix[i - 1][j - 1] + cost
                
                matrix[i][j] = [deletion, insertion, substitution].min()!
            }
        }
        
        return matrix[selfCount][otherCount]
    }
    
    /// Calculates the normalized Levenshtein distance as a percentage (0.0 to 1.0)
    /// where 0.0 means identical strings and 1.0 means completely different strings.
    ///
    /// - Parameter other: The string to compare against
    /// - Returns: Normalized distance as a Double between 0.0 and 1.0
    func normalizedLevenshteinDistance(to other: String) -> Double {
        let distance = levenshteinDistance(to: other)
        let maxLength = [self.count, other.count].max()!
        
        return maxLength == 0 ? 0.0 : Double(distance) / Double(maxLength)
    }
    
    /// Calculates the Levenshtein similarity as a percentage (0.0 to 1.0)
    /// where 1.0 means identical strings and 0.0 means completely different strings.
    ///
    /// - Parameter other: The string to compare against
    /// - Returns: Similarity as a Double between 0.0 and 1.0
    func levenshteinSimilarity(to other: String) -> Double {
        return 1.0 - normalizedLevenshteinDistance(to: other)
    }
    
    /// Checks if this string is similar to another string within a given threshold
    ///
    /// - Parameters:
    ///   - other: The string to compare against
    ///   - threshold: The similarity threshold (0.0 to 1.0). Default is 0.8
    /// - Returns: True if strings are similar within threshold, false otherwise
    func isSimilar(to other: String, threshold: Double = 0.8) -> Bool {
        return levenshteinSimilarity(to: other) >= threshold
    }
}
