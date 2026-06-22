//
//  BoundingBoxMatcher.swift
//  Onit
//
//  Created by Alex Carmack on 2024.
//

import Foundation
import CoreGraphics

/// Algorithm to match OCR observations with accessibility text bounding boxes based on spatial similarity
struct BoundingBoxMatcher {
    
    /// Configuration for bounding box matching
    struct MatchingConfig {
        
        /// Minimum overlap ratio required for a match (0.0 to 1.0)
        let minOverlapRatio: CGFloat = 0.4
        
        /// Maximum allowed size difference ratio (0.0 to 1.0)
        let maxSizeDifferenceRatio: CGFloat = 0.5
        
        /// Maximum allowed center distance as ratio of average bounds size
        let maxCenterDistanceRatio: CGFloat = 0.3
        
        /// Weight for overlap score (0.0 to 1.0)
        let overlapWeight: CGFloat = 0.4
        
        /// Weight for size similarity score (0.0 to 1.0)
        let sizeWeight: CGFloat = 0.3
        
        /// Weight for center distance score (0.0 to 1.0)
        let centerDistanceWeight: CGFloat = 0.3
    }
    
    /// Result of a bounding box match
    struct MatchResult {
        let accessibilityBox: TextBoundingBox
        let matchScore: CGFloat // 0.0 to 1.0, higher is better
        let overlapRatio: CGFloat
        let sizeSimilarity: CGFloat
        let centerDistance: CGFloat
    }
    
    private let config: MatchingConfig
    
    init(config: MatchingConfig = MatchingConfig()) {
        self.config = config
    }
    
    /// Find accessibility bounding boxes that match the given OCR observation
    /// - Parameters:
    ///   - ocrObservation: The OCR observation to match
    ///   - accessibilityBoxes: Available accessibility bounding boxes
    /// - Returns: Array of matches sorted by score (best first)
    func findMatches(for ocrObservation: OCRTextObservation, 
                    in accessibilityBoxes: [TextBoundingBox]) -> [MatchResult] {
        
        let ocrBounds = ocrObservation.bounds
        var matches: [MatchResult] = []
        
        for accessibilityBox in accessibilityBoxes {
            let accessibilityBounds = accessibilityBox.boundingBox
            
            // Calculate overlap
            let intersection = ocrBounds.intersection(accessibilityBounds)
            guard !intersection.isNull && !intersection.isEmpty else { continue }
            
            let overlapRatio = calculateOverlapRatio(intersection: intersection, 
                                                   rect1: ocrBounds, 
                                                   rect2: accessibilityBounds)
            
            // Skip if overlap is too small
            guard overlapRatio >= config.minOverlapRatio else { continue }
            
            // Calculate size similarity
            let sizeSimilarity = calculateSizeSimilarity(rect1: ocrBounds, rect2: accessibilityBounds)
            
            // Skip if size difference is too large
            let sizeDifferenceRatio = 1.0 - sizeSimilarity
            guard sizeDifferenceRatio <= config.maxSizeDifferenceRatio else { continue }
            
            // Calculate center distance
            let centerDistance = calculateCenterDistance(rect1: ocrBounds, rect2: accessibilityBounds)
            let averageSize = (min(ocrBounds.width, ocrBounds.height) + min(accessibilityBounds.width, accessibilityBounds.height)) / 2
            let normalizedCenterDistance = centerDistance / averageSize
            
            // Skip if centers are too far apart
            guard normalizedCenterDistance <= config.maxCenterDistanceRatio else { continue }
            
            // Calculate composite match score
            let centerDistanceScore = max(0, 1.0 - normalizedCenterDistance)
            let matchScore = (overlapRatio * config.overlapWeight) + 
                           (sizeSimilarity * config.sizeWeight) + 
                           (centerDistanceScore * config.centerDistanceWeight)
            
            let match = MatchResult(
                accessibilityBox: accessibilityBox,
                matchScore: matchScore,
                overlapRatio: overlapRatio,
                sizeSimilarity: sizeSimilarity,
                centerDistance: centerDistance
            )
            
            matches.append(match)
        }
        
        // Sort by score (best first)
        return matches.sorted { $0.matchScore > $1.matchScore }
    }
    
    /// Find the best matching accessibility bounding box for an OCR observation
    /// - Parameters:
    ///   - ocrObservation: The OCR observation to match
    ///   - accessibilityBoxes: Available accessibility bounding boxes
    /// - Returns: Best match or nil if no good match found
    func findBestMatch(for ocrObservation: OCRTextObservation, 
                      in accessibilityBoxes: [TextBoundingBox]) -> MatchResult? {
        let matches = findMatches(for: ocrObservation, in: accessibilityBoxes)
        return matches.first
    }
    
    // MARK: - Private Helper Methods
    
    private func calculateOverlapRatio(intersection: CGRect, rect1: CGRect, rect2: CGRect) -> CGFloat {
        let intersectionArea = intersection.width * intersection.height
        let rect1Area = rect1.width * rect1.height
        let rect2Area = rect2.width * rect2.height
        let unionArea = rect1Area + rect2Area - intersectionArea
        
        // Return Intersection over Union (IoU)
        return unionArea > 0 ? intersectionArea / unionArea : 0
    }
    
    private func calculateSizeSimilarity(rect1: CGRect, rect2: CGRect) -> CGFloat {
        let widthRatio = min(rect1.width, rect2.width) / max(rect1.width, rect2.width)
        let heightRatio = min(rect1.height, rect2.height) / max(rect1.height, rect2.height)
        
        // Average of width and height similarity
        return (widthRatio + heightRatio) / 2.0
    }
    
    private func calculateCenterDistance(rect1: CGRect, rect2: CGRect) -> CGFloat {
        let center1 = CGPoint(x: rect1.midX, y: rect1.midY)
        let center2 = CGPoint(x: rect2.midX, y: rect2.midY)
        
        let dx = center1.x - center2.x
        let dy = center1.y - center2.y
        
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - Extensions for easier usage

extension BoundingBoxMatcher {
    /// Batch process multiple OCR observations against accessibility boxes
    /// - Parameters:
    ///   - ocrObservations: Array of OCR observations to match
    ///   - accessibilityBoxes: Available accessibility bounding boxes
    /// - Returns: Dictionary mapping OCR observation indices to their best matches
    func findBestMatches(for ocrObservations: [OCRTextObservation], 
                        in accessibilityBoxes: [TextBoundingBox]) -> [Int: MatchResult] {
        var results: [Int: MatchResult] = [:]
        
        for (index, ocrObservation) in ocrObservations.enumerated() {
            if let bestMatch = findBestMatch(for: ocrObservation, in: accessibilityBoxes) {
                results[index] = bestMatch
            }
        }
        
        return results
    }
}
