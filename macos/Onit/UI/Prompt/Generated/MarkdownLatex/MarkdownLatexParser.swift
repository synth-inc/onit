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
        case code(String, String?)
        case latex(String)
    }
    
    func parse(_ text: String) async -> [Element] {
        var elements: [Element] = []
        
        let codeBlockPattern = "```(\\w*)\\n([\\s\\S]*?)\\n```"
        let codeBlockRegex = try! NSRegularExpression(pattern: codeBlockPattern, options: [])
        
        let nsText = text as NSString
        let matches = codeBlockRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        
        var lastEnd = 0
        
        for match in matches {
            if match.range.location > lastEnd {
                let textBefore = nsText.substring(with: NSRange(location: lastEnd, length: match.range.location - lastEnd))
                if !textBefore.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    elements.append(.text(textBefore))
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
                elements.append(.latex(content))
            } else {
                elements.append(.code(content, language))
            }
            
            lastEnd = match.range.location + match.range.length
        }
        
        if lastEnd < nsText.length {
            let remainingText = nsText.substring(from: lastEnd)
            if !remainingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                elements.append(.text(remainingText))
            }
        }
        
        var mergedElements: [Element] = []
        var currentText = ""
        
        for element in elements {
            switch element {
            case .text(let text):
                if !currentText.isEmpty {
                    currentText += "\n"
                }
                currentText += text
            case .code(_, _), .latex(_):
                if !currentText.isEmpty {
                    mergedElements.append(.text(currentText))
                    currentText = ""
                }
                mergedElements.append(element)
            }
        }
        
        if !currentText.isEmpty {
            mergedElements.append(.text(currentText))
        }
        
        print("KNA - Parsed elements:")
        for element in mergedElements {
            switch element {
            case .text(let text):
                print("KNA - Text (\(text.count) chars):", text.prefix(50))
            case .code(let code, let lang):
                print("KNA - Code (\(lang ?? "none")):", code.prefix(50))
            case .latex(let latex):
                print("KNA - LaTeX:", latex.prefix(50))
            }
        }
        
        return mergedElements
    }
}

private extension Substring {
    func toString() -> String {
        String(self)
    }
}
