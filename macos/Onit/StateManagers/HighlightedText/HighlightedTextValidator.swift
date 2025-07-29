//
//  HighlightedTextValidator.swift
//  Onit
//
//  Created by Kévin Naudin on 29/01/2025.
//

import ApplicationServices

struct HighlightedTextValidator {

    static func isValid(element: AXUIElement) -> Bool {
        guard element.role() == "AXTextField" else { return true }

        guard let description = element.description() else {
            // Arc
            if let placeholder = element.attribute(
                forAttribute: kAXPlaceholderValueAttribute as CFString)
                as? String,
                placeholder == "Search or Enter URL…"
            {
                return false
            }
            return true
        }

        switch description {

        // Chrome + Microsoft Edge
        case "Address and search bar":
            return false
        // Firefox
        case "Search or enter address":
            return false
        // Safari
        case "Smart Search Field", "Enter website name":
            return false
        // Opera
        case "Address field":
            return false

        default:
            return true
        }
    }
    
    static func isValid(text: String) -> Bool {
        guard !text.isEmpty else { return false }
        guard text.count >= 3 else { return false }
        
        return true
    }
}
