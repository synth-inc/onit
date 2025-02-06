//
//  AccessibilityParserBase.swift
//  Onit
//
//  Created by Kévin Naudin on 20/01/2025.
//

import ApplicationServices.HIServices.AXRoleConstants
import ApplicationServices.HIServices.AXUIElement

/// Base parser providing common parsing logic.
class AccessibilityParserBase: AccessibilityParserLogic {

    // MARK: - AccessibilityParserLogic

    /**
     * Default parsing logic to retrieve basic accessibility data.
     * - parameter element: The `AXUIElement` to parse
     * - returns: A dictionary containing general data.
     */
    func parse(element: AXUIElement) -> [String: String]? {
        if let role = element.role(), let title = element.title() {
            switch role {
            case kAXApplicationRole:
                return [AccessibilityParsedElements.applicationName: title]
            case kAXWindowRole:
                return [AccessibilityParsedElements.applicationTitle: title]
            default:
                return nil
            }
        }

        return nil
    }
}
