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
    override func parse(element: AXUIElement) -> [String: String] {
        var result: [String: String] = [:]
        var messagesContent: String = ""
        var highlightedTextFound = false

        _ = AccessibilityParserUtility.recursivelyParse(
            element: element,
            maxDepth: AccessibilityParserConfig.recursiveDepthMax
        ) { element, depth in
            if !highlightedTextFound {
                let parentResult = super.parse(element: element)
                
                if !parentResult.isEmpty {
                    highlightedTextFound = true
                    result.merge(parentResult) { _, new in new }
                }
            }
          
            // Get all accessibility attributes for the element
//             if let attributes = element.attributes() {
//                 let indent = String(repeating: "  ", count: depth)
//                 print("\(indent)Element attributes for \(element.title() ?? "unknown"):")
//                 for attribute in attributes {
//                     if let value = element.attribute(forAttribute: attribute as CFString) {
//                         print("\(indent)  \(attribute): \(value)")
//                     }
//                 }
//                 print("\(indent)---")
//             }
            
            guard let role = element.role(),
                  (role == kAXStaticTextRole || role == kAXGroupRole),
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

            return .continueRecursing(nil)
        }
        
        if !messagesContent.isEmpty {
            result[AccessibilityParsedElements.screen] = messagesContent
        }
        
        return result
    }
} 
