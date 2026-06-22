//
//  AccessibilityTextExtractor.swift
//  Onit
//
//  Created by Kévin Naudin on 09/29/2025.
//

import Foundation
import ApplicationServices

// MARK: - Error Types

enum AccessibilityTextExtractionError: Error {
    case elementHasNoValue
    case invalidCursorPosition
    case textRangeOutOfBounds
    case selectedTextNotFound
    
    var localizedDescription: String {
        switch self {
        case .elementHasNoValue:
            return "The accessibility element has no text value"
        case .invalidCursorPosition:
            return "The cursor position is invalid or out of bounds"
        case .textRangeOutOfBounds:
            return "The specified text range is out of bounds"
        case .selectedTextNotFound:
            return "The selected text could not be found in the element"
        }
    }
}

// MARK: - Data Structures

struct TextCursorContext {
    let fullText: String
    let textBeforeCursor: String
    let textAfterCursor: String
    let currentPartialWord: String?
    let cursorPosition: Int
}

struct TextSplitResult {
    let precedingText: String
    let followingText: String
    let splitPosition: Int
}

@MainActor
class AccessibilityTextExtractor {
    
    // MARK: - Singleton
    
    static let shared = AccessibilityTextExtractor()
    
    private struct TextOccurrence {
        let range: Range<String.Index>
        let startPosition: Int
        let endPosition: Int
    }
    
    // MARK: - Private initializer
    
    private init() {}
    
    // MARK: - Public Methods
    
    func extractTextCursorContext(from element: AXUIElement) throws -> TextCursorContext {
        guard let fullText = element.value() else {
            throw AccessibilityTextExtractionError.elementHasNoValue
        }

        let cursorPosition = getCursorPosition(from: element)
        let textBeforeCursor = extractTextBeforeCursor(fullText: fullText, cursorPosition: cursorPosition)
        let textAfterCursor = extractTextAfterCursor(fullText: fullText, cursorPosition: cursorPosition)
        let currentPartialWord = textBeforeCursor.components(separatedBy: .whitespacesAndNewlines).last
        
        return TextCursorContext(
            fullText: fullText,
            textBeforeCursor: textBeforeCursor,
            textAfterCursor: textAfterCursor,
            currentPartialWord: currentPartialWord,
            cursorPosition: cursorPosition
        )
    }
    
    func splitTextAroundSelection(element: AXUIElement, selectedText: String) throws -> TextSplitResult {
        guard let fullText = element.value() else {
            throw AccessibilityTextExtractionError.elementHasNoValue
        }
        
        let reportedCursorPosition = getCursorPosition(from: element)
        
        // First, check if the reported cursor position is correct
        if validateCursorPosition(fullText: fullText, selectedText: selectedText, cursorPosition: reportedCursorPosition) {
            // Split at the end of the selected text to exclude it from following text
            let endPosition = reportedCursorPosition + selectedText.count
            let (preceding, following) = splitTextAtPosition(fullText, position: endPosition)
            return TextSplitResult(precedingText: preceding, followingText: following, splitPosition: endPosition)
        }
        
        // If the reported position is incorrect, find all occurrences of the selected text
        let occurrences = findAllOccurrences(of: selectedText, in: fullText)
        
        let selectedEndPosition: Int
        if occurrences.isEmpty {
            throw AccessibilityTextExtractionError.selectedTextNotFound
        } else if occurrences.count == 1 {
            selectedEndPosition = occurrences[0].endPosition
        } else {
            // If multiple occurrences, choose the one closest to the reported position
            let closestOccurrence = occurrences.min { occurrence1, occurrence2 in
                let distance1 = abs(occurrence1.startPosition - reportedCursorPosition)
                let distance2 = abs(occurrence2.startPosition - reportedCursorPosition)
                return distance1 < distance2
            }
            selectedEndPosition = closestOccurrence?.endPosition ?? (reportedCursorPosition + selectedText.count)
        }
        
        let (preceding, following) = splitTextAtPosition(fullText, position: selectedEndPosition)
        return TextSplitResult(precedingText: preceding, followingText: following, splitPosition: selectedEndPosition)
    }

	func splitTextAtPosition(_ text: String, position: Int) -> (preceding: String, following: String) {
        let safePosition = max(0, min(position, text.count))
        
        let precedingIndex = text.index(text.startIndex, offsetBy: safePosition)
        let preceding = String(text[..<precedingIndex])
        let following = String(text[precedingIndex...])
        
        return (preceding, following)
    }
    
    // MARK: - Private Functions
    
    private func getCursorPosition(from element: AXUIElement) -> Int {
        return element.selectedTextRange()?.location ?? 0
    }
    
    private func extractTextBeforeCursor(fullText: String, cursorPosition: Int) -> String {
        let safePosition = max(0, min(cursorPosition, fullText.count))
        return String(fullText.prefix(safePosition))
    }
    
    private func extractTextAfterCursor(fullText: String, cursorPosition: Int) -> String {
        let safePosition = max(0, min(cursorPosition, fullText.count))
        let startIndex = fullText.index(fullText.startIndex, offsetBy: safePosition)
        return String(fullText[startIndex...])
    }
    
    private func validateCursorPosition(fullText: String, selectedText: String, cursorPosition: Int) -> Bool {
        guard cursorPosition >= 0 && cursorPosition <= fullText.count else { return false }
        
        // Check if the text at the cursor position matches the selected text
        let startIndex = fullText.index(fullText.startIndex, offsetBy: cursorPosition)
        let endIndex = fullText.index(startIndex, offsetBy: min(selectedText.count, fullText.count - cursorPosition))
        
        let textAtPosition = String(fullText[startIndex..<endIndex])
        
        return textAtPosition == selectedText
    }
    
    private func findAllOccurrences(of searchText: String, in fullText: String) -> [TextOccurrence] {
        var occurrences: [TextOccurrence] = []
        
        var searchStartIndex = fullText.startIndex
        while let range = fullText.range(of: searchText, range: searchStartIndex..<fullText.endIndex) {
            let startPosition = fullText.distance(from: fullText.startIndex, to: range.lowerBound)
            let endPosition = fullText.distance(from: fullText.startIndex, to: range.upperBound)
            occurrences.append(TextOccurrence(range: range, startPosition: startPosition, endPosition: endPosition))
            searchStartIndex = range.upperBound
        }
        
        return occurrences
    }
}
