//
//  AccessibilityParserGeneric.swift
//  Onit
//
//  Created by Kévin Naudin on 20/01/2025.
//

import ApplicationServices.HIServices.AXUIElement

/// Generic  implementation of the ``AccessibilityParserLogic``
class AccessibilityParserGeneric: AccessibilityParserLogic {

    // MARK: - AccessibilityParserLogic

    /** See ``AccessibilityParserLogic`` parse function */
    func parse(element: AXUIElement) -> [String: String] {
        var result: [String: String] = [:]
        var screen: String = ""
        
        _ = AccessibilityParserUtility.recursivelyParse(
            element: element,
            maxDepth: AccessibilityParserConfig.recursiveDepthMax
        ) { element in
            
            if let value = element.value(), !value.isEmpty {
                screen += "\(value) "
            }

            return nil
        }

        result[AccessibilityParsedElements.screen] = screen

        return result
    }
}
