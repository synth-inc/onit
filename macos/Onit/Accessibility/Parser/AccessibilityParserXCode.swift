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
    override func parse(element: AXUIElement) -> [String: String] {
        var result: [String: String] = [:]
        var highlightedTextFound = false

        return AccessibilityParserUtility.recursivelyParse(
            element: element,
            maxDepth: AccessibilityParserConfig.recursiveDepthMax
        ) { element in
            
            if !highlightedTextFound {
                let parentResult = super.parse(element: element)
                
                if !parentResult.isEmpty {
                    highlightedTextFound = true
                    result.merge(parentResult) { _, new in new }
                }
            }
            
            guard let description = element.description(),
                  description != "Console",
                  let role = element.role(),
                  role == kAXTextAreaRole,
                  let value = element.value(),
                  !value.isEmpty
            else {
                return result
            }

            switch description {
            case "Source Editor":
                result[AccessibilityParsedElements.Xcode.editor] = value
            default:
                break
            }

            return result
        }
    }
}
