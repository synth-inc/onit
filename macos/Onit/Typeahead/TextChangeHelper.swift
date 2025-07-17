//
//  TextChangeHelper.swift
//  Onit
//
//  Created by Timothy Lenardo on 6/18/25.
//

import Foundation

// MARK: - Text Change Types

enum TextChangeType: String {
    case addition = "addition"
    case deletion = "deletion"
    case modification = "modification"
}

struct TextChange {
    let type: TextChangeType
    let addedText: String?
    let deletedText: String?
    let insertionIndex: Int? // Position where the change occurred
    let textPrefixRange: NSRange? // Range of text before the edit
    let textSuffixRange: NSRange? // Range of text after the edit
    
    // This is for the main ones, to create the test cases.
    var initialText: String?
    var endText: String?
    var trigger: String?
}

// MARK: - Text Change Helper
@MainActor
final class TextChangeHelper {
    static let shared = TextChangeHelper()
    
    private init() {}
    
    /// Helper struct to return corrected prefix/suffix lengths
    private struct CorrectedLengths {
        let prefixLength: Int
        let suffixLength: Int
    }
    
    /// Resolves ambiguity in prefix/suffix calculation using keystroke information
    private func resolveAmbiguityWithKeystrokes(
        old: String, new: String, typedText: String, keystrokes: [String],
        initialPrefixLength: Int, initialSuffixLength: Int
    ) -> CorrectedLengths? {
        
        // First, check for special key combinations that modify text in non-character ways
        if let specialResolution = resolveSpecialKeyOperations(old: old, new: new, keystrokes: keystrokes, initialPrefixLength: initialPrefixLength, initialSuffixLength: initialSuffixLength) {
            return specialResolution
        }
        
        // Only attempt character-based resolution for cases where typed text is meaningful
        guard !typedText.isEmpty else {
            return nil
        }
        
        // For addition cases, try character-based matching
        if new.count > old.count {
            if let additionResolution = resolveAdditionAmbiguity(old: old, new: new, typedText: typedText, initialPrefixLength: initialPrefixLength, initialSuffixLength: initialSuffixLength) {
                return additionResolution
            }
        }
        
        // For deletion cases, try different heuristics
        if new.count < old.count {
            if let deletionResolution = resolveDeletionAmbiguity(old: old, new: new, keystrokes: keystrokes, initialPrefixLength: initialPrefixLength, initialSuffixLength: initialSuffixLength) {
                return deletionResolution
            }
        }
        
        return nil
    }
    
    /// Handles special key operations like paste, cut, undo, etc.
    private func resolveSpecialKeyOperations(
        old: String, new: String, keystrokes: [String],
        initialPrefixLength: Int, initialSuffixLength: Int
    ) -> CorrectedLengths? {
        
        // Check for paste operations (CMD+V)
        if keystrokes.contains("cmd+v") {
            return resolvePasteOperation(old: old, new: new, keystrokes: keystrokes, initialPrefixLength: initialPrefixLength, initialSuffixLength: initialSuffixLength)
        }
        
        // Check for cut operations (CMD+X)
        if keystrokes.contains("cmd+x") {
            return resolveCutOperation(old: old, new: new, initialPrefixLength: initialPrefixLength, initialSuffixLength: initialSuffixLength)
        }
        
        // Check for undo operations (CMD+Z)
        if keystrokes.contains("cmd+z") || keystrokes.contains("cmd+shift+z") {
            return resolveUndoOperation(old: old, new: new, keystrokes: keystrokes, initialPrefixLength: initialPrefixLength, initialSuffixLength: initialSuffixLength)
        }
        
        // Check for select all + replacement (CMD+A followed by typing)
        if let selectAllIndex = keystrokes.firstIndex(of: "cmd+a") {
            let hasTypingAfterSelectAll = keystrokes.count > selectAllIndex + 1
            if hasTypingAfterSelectAll {
                return resolveSelectAllReplacement(old: old, new: new, keystrokes: keystrokes, selectAllIndex: selectAllIndex)
            }
        }
        
        return nil
    }
    
    /// Resolves paste operations (CMD+V)
    private func resolvePasteOperation(
        old: String, new: String, keystrokes: [String],
        initialPrefixLength: Int, initialSuffixLength: Int
    ) -> CorrectedLengths? {
        
        // For paste operations, we need to figure out where the paste occurred
        // Heuristic: Look for the most logical insertion point
        
        // If new text is much longer than old, likely a paste at cursor position
        let sizeDifference = new.count - old.count
        
        // Try to find where the old text appears in the new text
        if let range = new.range(of: old) {
            let oldStartIndex = new.distance(from: new.startIndex, to: range.lowerBound)
            
            // If old text appears at the beginning, paste was at the end
            if oldStartIndex == 0 {
                return CorrectedLengths(prefixLength: old.count, suffixLength: 0)
            }
            
            // If old text appears at the end, paste was at the beginning  
            let oldEndIndex = oldStartIndex + old.count
            if oldEndIndex == new.count {
                return CorrectedLengths(prefixLength: 0, suffixLength: old.count)
            }
            
            // Old text appears in the middle, paste was either before or after
            // Use the paste position to determine prefix/suffix
            return CorrectedLengths(prefixLength: oldStartIndex, suffixLength: new.count - oldEndIndex)
        }
        
        // Fallback: assume paste at current cursor position (use original calculation but bias toward insertion)
        return CorrectedLengths(prefixLength: initialPrefixLength, suffixLength: initialSuffixLength)
    }
    
    /// Resolves cut operations (CMD+X)
    private func resolveCutOperation(
        old: String, new: String,
        initialPrefixLength: Int, initialSuffixLength: Int
    ) -> CorrectedLengths? {
        
        // For cut operations, text was removed
        // Try to find where the new text appears in the old text
        if let range = old.range(of: new) {
            let newStartIndex = old.distance(from: old.startIndex, to: range.lowerBound)
            let newEndIndex = newStartIndex + new.count
            
            // Text was cut from the beginning: old="Hello world", new="world" -> cut happened at index 0
            if newEndIndex == old.count {
                return CorrectedLengths(prefixLength: 0, suffixLength: new.count)
            }
            
            // Text was cut from the end: old="Hello world", new="Hello" -> cut happened at the end
            if newStartIndex == 0 {
                return CorrectedLengths(prefixLength: new.count, suffixLength: 0)
            }
            
            // The cut happened in the middle - deletion at the gap before remaining text
            return CorrectedLengths(prefixLength: newStartIndex, suffixLength: old.count - newEndIndex)
        }
        
        // Fallback: use original calculation
        return CorrectedLengths(prefixLength: initialPrefixLength, suffixLength: initialSuffixLength)
    }
    
    /// Resolves undo/redo operations (CMD+Z, CMD+Shift+Z)
    private func resolveUndoOperation(
        old: String, new: String, keystrokes: [String],
        initialPrefixLength: Int, initialSuffixLength: Int
    ) -> CorrectedLengths? {
        
        // Undo operations can add or remove text
        // We can't know exactly what was undone, so use heuristics
        
        let isRedo = keystrokes.contains("cmd+shift+z")
        
        // If text was added by undo/redo, assume it was added at cursor position
        if new.count > old.count {
            // Try to find where old text appears in new text
            if let range = new.range(of: old) {
                let oldStartIndex = new.distance(from: new.startIndex, to: range.lowerBound)
                let oldEndIndex = oldStartIndex + old.count
                return CorrectedLengths(prefixLength: oldStartIndex, suffixLength: new.count - oldEndIndex)
            }
        }
        
        // If text was removed by undo/redo
        if new.count < old.count {
            // Try to find where new text appears in old text
            if let range = old.range(of: new) {
                let newStartIndex = old.distance(from: old.startIndex, to: range.lowerBound)
                return CorrectedLengths(prefixLength: newStartIndex, suffixLength: old.count - newStartIndex - new.count)
            }
        }
        
        // Fallback: use original calculation
        return CorrectedLengths(prefixLength: initialPrefixLength, suffixLength: initialSuffixLength)
    }
    
    /// Resolves select all + replacement operations
    private func resolveSelectAllReplacement(
        old: String, new: String, keystrokes: [String], selectAllIndex: Int
    ) -> CorrectedLengths? {
        
        // After CMD+A, all text was selected and then replaced
        // The replacement text is everything that was typed after CMD+A
        let keystrokesAfterSelectAll = Array(keystrokes[(selectAllIndex + 1)...])
        
        // All old text was replaced, so prefix=0, suffix=0
        return CorrectedLengths(prefixLength: 0, suffixLength: 0)
    }
    
    /// Resolves addition ambiguity using character-based matching
    private func resolveAdditionAmbiguity(
        old: String, new: String, typedText: String,
        initialPrefixLength: Int, initialSuffixLength: Int
    ) -> CorrectedLengths? {
        
        // Check if the typed text appears at the beginning of the new text
        if new.hasPrefix(typedText) {
            
            let remainingText = String(new.dropFirst(typedText.count))
            if remainingText == old {
                return CorrectedLengths(prefixLength: 0, suffixLength: old.count)
            }
        }
        
        // Check if typed text appears elsewhere and can resolve the ambiguity
        if let range = new.range(of: typedText) {
            let typedStartIndex = new.distance(from: new.startIndex, to: range.lowerBound)
            
            if typedStartIndex == 0 {
                let afterTyped = String(new.dropFirst(typedText.count))
                if afterTyped == old || old.hasPrefix(afterTyped) || afterTyped.hasPrefix(old) {
                    return CorrectedLengths(prefixLength: 0, suffixLength: min(afterTyped.count, old.count))
                }
            }
        }
        
        // Handle the specific edge case: when typed text starts with same characters as original
        if !old.isEmpty && !typedText.isEmpty {
            let oldChars = Array(old)
            let typedChars = Array(typedText)
            
            var matchingPrefixLength = 0
            let maxCheck = min(oldChars.count, typedChars.count)
            
            while matchingPrefixLength < maxCheck && 
                  oldChars[matchingPrefixLength] == typedChars[matchingPrefixLength] {
                matchingPrefixLength += 1
            }
            
            if matchingPrefixLength > 0 {
                
                let adjustedPrefixLength = max(0, initialPrefixLength - matchingPrefixLength)
                let adjustedSuffixLength = initialSuffixLength + matchingPrefixLength
                
                let newChars = Array(new)
                if adjustedSuffixLength <= newChars.count && adjustedPrefixLength >= 0 {
                    return CorrectedLengths(prefixLength: adjustedPrefixLength, suffixLength: adjustedSuffixLength)
                }
            }
        }
        
        return nil
    }
    
    /// Resolves deletion ambiguity using keystroke analysis
    private func resolveDeletionAmbiguity(
        old: String, new: String, keystrokes: [String],
        initialPrefixLength: Int, initialSuffixLength: Int
    ) -> CorrectedLengths? {
        
        // Look for delete keys in the keystroke sequence
        let hasBackspace = keystrokes.contains("delete")
        let hasForwardDelete = keystrokes.contains("forward_delete")
        
        if hasBackspace && !hasForwardDelete {
            // Backspace deletes to the left, so deletion likely happened before cursor
            // Bias toward keeping more suffix
            let biasedSuffixLength = min(initialSuffixLength + 2, new.count - initialPrefixLength)
            return CorrectedLengths(prefixLength: initialPrefixLength, suffixLength: biasedSuffixLength)
        }
        
        if hasForwardDelete && !hasBackspace {
            // Forward delete removes to the right, so deletion likely happened after cursor
            // Bias toward keeping more prefix
            let biasedPrefixLength = min(initialPrefixLength + 2, new.count - initialSuffixLength)
            return CorrectedLengths(prefixLength: biasedPrefixLength, suffixLength: initialSuffixLength)
        }
        
        // For other deletion cases, use original calculation
        return nil
    }
    
    /// Calculates the difference between two text strings and returns a TextChange object
    /// describing what changed between them.
    func calculateTextChangeFast(from oldValue: String?, to newValue: String?, keystrokes: [String]? = nil) -> TextChange? {
        guard let old = oldValue, let new = newValue else { 
            let result = newValue != nil ? TextChange(type: .addition, addedText: newValue, deletedText: nil, insertionIndex: 0, textPrefixRange: nil, textSuffixRange: nil) : nil
            return result
        }
        
        if old == new { 
            return nil 
        }
        
        let initialChars = Array(old)
        let newChars = Array(new)
        
        // Find common prefix
        var prefixLength = 0
        let minLength = min(initialChars.count, newChars.count)
        
        while prefixLength < minLength && initialChars[prefixLength] == newChars[prefixLength] {
            prefixLength += 1
        }
        
        // Find common suffix
        var suffixLength = 0
        let maxSuffixLength = minLength - prefixLength
        
        while suffixLength < maxSuffixLength && 
              initialChars[initialChars.count - 1 - suffixLength] == newChars[newChars.count - 1 - suffixLength] {
            suffixLength += 1
        }
        
        // Check for ambiguity and resolve using keystrokes if available
        var finalPrefixLength = prefixLength
        var finalSuffixLength = suffixLength
        
        if let keystrokes = keystrokes, !keystrokes.isEmpty {
            let typedText = KeyCodeTranslator.shared.keystrokesToText(keystrokes)
            
            // Check if there's potential ambiguity that keystrokes can help resolve
            if let correctedLengths = resolveAmbiguityWithKeystrokes(
                old: old, new: new, typedText: typedText, keystrokes: keystrokes,
                initialPrefixLength: prefixLength, initialSuffixLength: suffixLength
            ) {
                finalPrefixLength = correctedLengths.prefixLength
                finalSuffixLength = correctedLengths.suffixLength
            }
        }
        
        // Calculate what changed
        let initialMiddleStart = finalPrefixLength
        let initialMiddleEnd = initialChars.count - finalSuffixLength
        let newMiddleStart = finalPrefixLength
        let newMiddleEnd = newChars.count - finalSuffixLength
        
        let deletedText = initialMiddleStart < initialMiddleEnd ? 
            String(initialChars[initialMiddleStart..<initialMiddleEnd]) : ""
        let addedText = newMiddleStart < newMiddleEnd ? 
            String(newChars[newMiddleStart..<newMiddleEnd]) : ""
        
        // Calculate prefix and suffix from the new text
        let textPrefixRange: NSRange? = finalPrefixLength > 0 ? NSRange(location: 0, length: finalPrefixLength) : nil
        let textSuffixRange: NSRange? = finalSuffixLength > 0 ? NSRange(location: newChars.count - finalSuffixLength, length: finalSuffixLength) : nil
        
        // Determine change type and return appropriate result
        if deletedText.isEmpty && !addedText.isEmpty {
            return TextChange(type: .addition, addedText: addedText, deletedText: nil, insertionIndex: finalPrefixLength, textPrefixRange: textPrefixRange, textSuffixRange: textSuffixRange)
        } else if !deletedText.isEmpty && addedText.isEmpty {
            return TextChange(type: .deletion, addedText: nil, deletedText: deletedText, insertionIndex: finalPrefixLength, textPrefixRange: textPrefixRange, textSuffixRange: textSuffixRange)
        } else if !deletedText.isEmpty && !addedText.isEmpty {
            return TextChange(type: .modification, addedText: addedText, deletedText: deletedText, insertionIndex: finalPrefixLength, textPrefixRange: textPrefixRange, textSuffixRange: textSuffixRange)
        }
        
        return nil
    }
} 
