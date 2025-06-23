//
//  AccessibilityParserBase.swift
//  Onit
//
//  Created by Kévin Naudin on 30/04/2025.
//

import ApplicationServices.HIServices.AXUIElement
import Foundation

/// Base  implementation of the ``AccessibilityParserLogic``
class AccessibilityParserBase: AccessibilityParserLogic {

    // MARK: - AccessibilityParserLogic

    /** See ``AccessibilityParserLogic`` parse function */
    func parse(element: AXUIElement) async -> [String: String] {
        var results: [String: String] = [:]
        
        if let selectedText = element.selectedText(),
           HighlightedTextValidator.isValid(element: element) {
            results[AccessibilityParsedElements.highlightedText] = selectedText
        }

        return results
    }
}
