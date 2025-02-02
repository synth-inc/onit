//
//  AccessibilityTextSelectionFilter.swift
//  Onit
//
//  Created by Kévin Naudin on 29/01/2025.
//

import ApplicationServices

struct AccessibilityTextSelectionFilter {
    
    static func filter(element: AXUIElement) -> Bool {
        guard element.role() == "AXTextField" else { return false }
        
        guard let description = element.description() else {
            // Arc
            if let placeholder = element.attribute(forAttribute: kAXPlaceholderValueAttribute as CFString) as? String,
               placeholder == "Search or Enter URL…" {
                return true
            }
            return false
        }
        
        switch description {

        // Chrome + Microsoft Edge
        case "Address and search bar":
            return true
        // Firefox
        case "Search or enter address":
            return true
        // Safari
        case "Smart Search Field", "Enter website name":
            return true
        // Opera
        case "Address field":
            return true
            
        default:
            return false
        }
    }
}
