//
//  AccessibilityParserCalendar.swift
//  Onit
//
//  Created by Kévin Naudin on 28/04/2025.
//

import ApplicationServices.HIServices

/// Implementation of `AccessibilityParserLogic` for Calendar app
class AccessibilityParserCalendar: AccessibilityParserBase {

    // MARK: - AccessibilityParserLogic

    /** See ``AccessibilityParserLogic`` parse function */
    override func parse(element: AXUIElement, includeBoundingBoxes: Bool ) async -> ([String: String], [TextBoundingBox]?) {

        var result: [String: String] = [:]
        var screen: String = ""
        var highlightedTextFound = false
        var boundingBoxes : [TextBoundingBox] = []

        _ = await AccessibilityParserUtility.recursivelyParse(
            element: element,
            maxDepth: AccessibilityParserConfig.recursiveDepthMax
        ) { element, depth in
            
            if !highlightedTextFound {
                let (parentResult, parentBoundingBoxes) = await super.parse(element: element)
                
                if !parentResult.isEmpty {
                    highlightedTextFound = true
                    result.merge(parentResult) { _, new in new }
                }
            }
            
            guard let role = element.role(), role == kAXStaticTextRole,
                  let description = element.description(),
                  !description.isEmpty,
                  !screen.contains(description) else {
                return .continueRecursing(nil)
            }
            
            if includeBoundingBoxes, let frame = element.getFrame() {
                let textBoundingBox = TextBoundingBox(text: description, boundingBox: frame, elementRole: role, elementDescription: description)
                boundingBoxes.append(textBoundingBox)
            }
            screen += "\(description)\n"

            return .continueRecursing(nil)
        }
        
        result[AccessibilityParsedElements.screen] = screen
        
        return (result, includeBoundingBoxes ? boundingBoxes : nil)
    }
}
