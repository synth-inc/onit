//
//  AccessibilityParserXCode.swift
//  Onit
//
//  Created by Kévin Naudin on 20/01/2025.
//

import ApplicationServices.HIServices

/**
 * Implementation of `AccessibilityParserLogic` for Xcode app
 */
class AccessibilityParserXCode: AccessibilityParserBase {
    
    // MARK: - AccessibilityParserLogic
    
    /** See ``AccessibilityParserLogic`` parse function */
    override func parse(element: AXUIElement) -> [String : String] {
        var result: [String: String] = [:]
        let maxDepth = AccessibilityParserConfig.recursiveDepthMax
        
        return AccessibilityParserUtility.recursivelyParse(element: element,
                                                           maxDepth: maxDepth) { element in
            if let parentResult = super.parse(element: element) {
                result.merge(parentResult) { _, new in new }
            }
            
            guard let role = element.role(),
                  role == kAXTextAreaRole,
                  let description = element.description(),
                  let value = element.value(),
                  !value.isEmpty else {
                return result
            }
            
            switch description {
            case "Source Editor":
                result["editor"] = value
            case "Console":
                result["console"] = value
            default:
                break
            }
            
            return result
        }
    }
}
