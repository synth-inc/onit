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
        
        // Remove the last '\n'
        if plainText.last == "\n" {
            plainText.removeLast()
        }
        
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
            
        case is LineBreak:
            return "\n"
        case is SoftBreak:
            return " "
        
        case let codeBlock as CodeBlock:
            let code = codeBlock.code
            return "\n\(code)\n"
        
        case let inlineCode as InlineCode:
            return inlineCode.code
            
        case let unorderedList as UnorderedList:
            return formatUnorderedList(unorderedList)
            
        case let orderedList as OrderedList:
            return formatOrderedList(orderedList)
        
        case let heading as Heading:
            return heading.children.map { $0.plainText }.joined() + "\n"
            
        case let text as Text:
            return text.string
        case let link as Link:
            return link.children.map { $0.plainText }.joined()
        default:
            return children.map { $0.plainText }.joined()
        }
    }
    
    private func formatUnorderedList(_ list: UnorderedList) -> String {
        var result = ""
        
        for item in list.listItems {
            let itemText = item.children.map { $0.plainText }.joined()
            
            result += "• \(itemText)"
        }
        
        return result
    }
    
    private func formatOrderedList(_ list: OrderedList) -> String {
        var result = ""
        
        for (index, item) in list.listItems.enumerated() {
            let itemText = item.children.map { $0.plainText }.joined()
            result += "\(index + 1). \(itemText)"
        }
        
        return result
    }
}
