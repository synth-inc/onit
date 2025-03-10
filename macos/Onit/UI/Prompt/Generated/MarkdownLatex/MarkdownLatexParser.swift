//
//  MarkdownLatexParser.swift
//  Onit
//
//  Created by Kévin Naudin on 07/03/2025.
//

import SwiftUI

@MainActor
@objc class MarkdownLatexParser: NSObject {
    enum Element {
        case text(String)
        case code(String, String?, Bool) // content, language, isGenerating
        case latex(String, Bool) // content, isGenerating
    }
    
    func parse(_ text: String) async -> [Element] {
        var elements: [Element] = []
        
        // Pattern to match both complete and incomplete code blocks
        let completeBlockPattern = "```(\\w*)\\n([\\s\\S]*?)\\n```"
        let incompleteBlockPattern = "```(\\w*)\\n([\\s\\S]*?)$"
        
        let completeBlockRegex = try! NSRegularExpression(pattern: completeBlockPattern, options: [])
        let incompleteBlockRegex = try! NSRegularExpression(pattern: incompleteBlockPattern, options: [])
        
        let nsText = text as NSString
        var lastEnd = 0
        
        // First, handle complete blocks
        let completeMatches = completeBlockRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        
        for match in completeMatches {
            if match.range.location > lastEnd {
                let textBefore = nsText.substring(with: NSRange(location: lastEnd, length: match.range.location - lastEnd))
                let normalizedText = textBefore.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .newlines)
                if !normalizedText.isEmpty {
                    elements.append(.text(normalizedText))
                }
            }
            
            let languageRange = match.range(at: 1)
            let contentRange = match.range(at: 2)
            
            let language = languageRange.location != NSNotFound ? nsText.substring(with: languageRange) : nil
            var content = contentRange.location != NSNotFound ? nsText.substring(with: contentRange) : ""
            
            if content.hasPrefix("\n") {
                content = String(content.dropFirst())
            }
            if content.hasSuffix("\n") {
                content = String(content.dropLast())
            }
            
            if language == "latex" {
                elements.append(.latex(content, false)) // Complete block, not generating
            } else {
                elements.append(.code(content, language, false)) // Complete block, not generating
            }
            
            lastEnd = match.range.location + match.range.length
        }
        
        // Then, handle incomplete blocks at the end
        if lastEnd < nsText.length {
            let remainingText = nsText.substring(from: lastEnd) as String
            let incompleteMatches = incompleteBlockRegex.matches(in: remainingText, options: [], range: NSRange(location: 0, length: remainingText.count))
            
            if let incompleteMatch = incompleteMatches.last {
                let beforeIncomplete = remainingText[..<remainingText.index(remainingText.startIndex, offsetBy: incompleteMatch.range.location)]
                let normalizedText = beforeIncomplete.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .newlines)
                if !normalizedText.isEmpty {
                    elements.append(.text(normalizedText))
                }
                
                let languageRange = incompleteMatch.range(at: 1)
                let contentRange = incompleteMatch.range(at: 2)
                
                let language = languageRange.location != NSNotFound ? (remainingText as NSString).substring(with: languageRange) : nil
                var content = contentRange.location != NSNotFound ? (remainingText as NSString).substring(with: contentRange) : ""
                
                if content.hasPrefix("\n") {
                    content = String(content.dropFirst())
                }
                
                if language == "latex" {
                    elements.append(.latex(content, true)) // Incomplete block, still generating
                } else {
                    elements.append(.code(content, language, true)) // Incomplete block, still generating
                }
            } else if !remainingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let normalizedText = remainingText.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .newlines)
                elements.append(.text(normalizedText))
            }
        }
        
        return elements
    }
}

private extension Substring {
    func toString() -> String {
        String(self)
    }
}
