//
//  AccessibilityParserGeneric.swift
//  Onit
//
//  Created by Kévin Naudin on 20/01/2025.
//

import ApplicationServices.HIServices.AXUIElement

/// Generic  implementation of the ``AccessibilityParserLogic``
class AccessibilityParserGeneric: AccessibilityParserBase {

    // MARK: - AccessibilityParserLogic

    /** See ``AccessibilityParserLogic`` parse function */
    override func parse(element: AXUIElement) -> [String: String] {
        var result: [String: String] = [:]
        var screen: String = ""
        
        _ = AccessibilityParserUtility.recursivelyParse(
            element: element,
            maxDepth: Config.recursiveDepthMax
        ) { element in
            if let parentResult = super.parse(element: element) {
                result.merge(parentResult) { _, new in new }
            }

            if let value = element.value(), !value.isEmpty {
                screen += "\(value) "
            }
            //            if let title = element.attribute(forAttribute: kAXTitleAttribute as CFString) as? String, !title.isEmpty {
            //                screen += "title: \(title)\n"
            //            }
            //            if let description = element.attribute(forAttribute: kAXDescriptionAttribute as CFString) as? String, !description.isEmpty {
            //                screen += "description: \(description)\n"
            //            }

            return nil
        }

        result[AccessibilityParsedElements.screen] = screen

        return result
    }
}
