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
    override func parse(element: AXUIElement) -> [String: String] {
        var result: [String: String] = [:]
        var screen: String = ""
        var highlightedTextFound = false

        _ = AccessibilityParserUtility.recursivelyParse(
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
            
            guard let role = element.role(), role == kAXStaticTextRole,
                  let description = element.description(),
                  !description.isEmpty,
                  !screen.contains(description) else {
                return nil
            }
            
            screen += "\(description)\n"

            return nil
        }
        
        result[AccessibilityParsedElements.screen] = screen
        
        return result
    }
}
