//
//  String+Markdown.swift
//  Onit
//
//  Created by Kévin Naudin on 29/01/2025.
//

import Markdown

extension String {
    
    /** Remove all markdown from code */
    func stripMarkdown() -> String {
        let document = Document(parsing: self)
        var plainText = document.plainText
        
        plainText.removeLast()
        
        return plainText
    }
}

extension Document {
    var plainText: String {
        var text = ""
        for child in children {
            text += child.plainText
        }
        return text
    }
}

extension Markup {
    var plainText: String {
        switch self {
        case is Paragraph:
            return children.map { $0.plainText }.joined() + "\n"
        case let text as Text:
            return text.string
        case is LineBreak:
            return "\n"
        case is SoftBreak:
            return " "
        case is InlineCode, is InlineHTML:
            return ""
        case let link as Link:
            return link.children.map { $0.plainText }.joined()
        default:
            return children.map { $0.plainText }.joined()
        }
    }
}
