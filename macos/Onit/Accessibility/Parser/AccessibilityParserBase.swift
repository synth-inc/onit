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
    func parse(element: AXUIElement, includeBoundingBoxes: Bool = false) async -> ([String: String], [TextBoundingBox]?) {

        var results: [String: String] = [:]
        var boundingBoxes: [TextBoundingBox] = []
        
        if let selectedText = element.selectedText(),
           HighlightedTextValidator.isValid(element: element) {
            results[AccessibilityParsedElements.highlightedText] = selectedText
            
            if includeBoundingBoxes, let frame = element.getFrame() {
                let textBoundingBox = TextBoundingBox(
                    text: selectedText,
                    boundingBox: frame,
                    elementRole: element.role(),
                    elementDescription: element.description()
                )
                boundingBoxes.append(textBoundingBox)
            }
        }

        return (results, includeBoundingBoxes ? boundingBoxes : nil)
    }
}
