//
//  AccessibilityParserXCode.swift
//  Onit
//
//  Created by Kévin Naudin on 20/01/2025.
//

import ApplicationServices.HIServices

/// Implementation of `AccessibilityParserLogic` for Xcode app
class AccessibilityParserXCode: AccessibilityParserBase {

    // MARK: - AccessibilityParserLogic

    /** See ``AccessibilityParserLogic`` parse function */
    override func parse(element: AXUIElement, includeBoundingBoxes: Bool ) async -> ([String: String], [TextBoundingBox]?) {
        var result: [String: String] = [:]
        var highlightedTextFound = false
        var boundingBoxes : [TextBoundingBox] = []
        
        result = await AccessibilityParserUtility.recursivelyParse(
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
            
            guard let description = element.description(),
                  let role = element.role(),
                  role == kAXTextAreaRole,
                  let frame = element.getFrame(),
                  let value = element.value(),
                  !value.isEmpty
            else {
                return .continueRecursing(result.isEmpty ? nil : result)
            }
            
            // Stop recursing if we hit "Console" but don't process this element
            if description == "Console" {
                return .stopRecursing(result.isEmpty ? nil : result)
            }
            
            switch description {
            case "Source Editor":
                result[AccessibilityParsedElements.Xcode.editor] = value
                boundingBoxes.append(TextBoundingBox(text: value, boundingBox: frame, elementRole: role, elementDescription: description))
            default:
                break
            }
            return .continueRecursing(result.isEmpty ? nil : result)
        }
        return (result, includeBoundingBoxes ? boundingBoxes : nil)
    }
}
