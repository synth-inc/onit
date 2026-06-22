//
//  AccessibilityParserMessages.swift
//  Onit
//
//  Created by Assistant on 23/01/2025.
//

import ApplicationServices.HIServices

/// Implementation of `AccessibilityParserLogic` for Messages app
class AccessibilityParserMessages: AccessibilityParserBase {

    // MARK: - AccessibilityParserLogic

    /** See ``AccessibilityParserLogic`` parse function */
    override func parse(element: AXUIElement, includeBoundingBoxes: Bool ) async -> ([String: String], [TextBoundingBox]?) {
        var result: [String: String] = [:]
        var messagesContent: String = ""
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
          
            
            guard let role = element.role(),
                  (role == kAXStaticTextRole || role == kAXGroupRole),
                  let frame = element.getFrame(),
                  let description = element.description(),
                  !description.isEmpty,
                  !messagesContent.contains(description)
            else {
                return .continueRecursing(nil)
            }

            // Stop recursing if we hit "Conversations" but still process this element
            if description == "Conversations" {
                return .stopRecursing(nil)
            }
        
            print("Adding \(description)")
            messagesContent += "\(description)\n"
            boundingBoxes.append(TextBoundingBox(text:description, boundingBox: frame, elementRole: role, elementDescription: nil))
            
            return .continueRecursing(nil)
        }
        
        if !messagesContent.isEmpty {
            result[AccessibilityParsedElements.screen] = messagesContent
        }
        
        return (result, includeBoundingBoxes ? boundingBoxes : nil)
    }
} 
