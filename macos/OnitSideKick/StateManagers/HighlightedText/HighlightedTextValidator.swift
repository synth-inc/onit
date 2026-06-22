//
//  HighlightedTextValidator.swift
//  Onit
//
//  Created by Kévin Naudin on 29/01/2025.
//

import ApplicationServices

struct HighlightedTextValidator {

    static func isValid(element: AXUIElement) -> Bool {
        return !element.isBrowserURLBar()
    }
    
    static func isValid(text: String) -> Bool {
        guard !text.isEmpty else { return false }
        guard text.count >= 3 else { return false }
        
        return true
    }
}
