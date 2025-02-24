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

        return AccessibilityParserUtility.recursivelyParse(
            element: element,
            maxDepth: Config.recursiveDepthMax
        ) { element in
            if let parentResult = super.parse(element: element) {
                result.merge(parentResult) { _, new in new }
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
