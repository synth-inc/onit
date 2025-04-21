//
//  AccessibilityParser.swift
//  Onit
//
//  Created by Kévin Naudin on 15/01/2025.
//

import AppKit
import ApplicationServices

/// This class is used for parsing accessibility attributes using `Accessibility` API.
/// Starting by the root `AXUIElement`
@MainActor
class AccessibilityParser {

    static let shared = AccessibilityParser()

    private let genericParser = AccessibilityParserGeneric()
    private let parsers: [String: AccessibilityParserLogic] = [
        "Xcode": AccessibilityParserXCode()
    ]

    // MARK: - Functions

    func getAllTextInElement(windowElement: AXUIElement) async -> [String: String]? {
        let startTime = CFAbsoluteTimeGetCurrent()

        let appName = windowElement.parent()?.title() ?? "Unknown"
        let parser = parsers[appName] ?? genericParser

//        var debugText = "App found: \(appName) use of parser \(parser)\n"

        var results = parser.parse(element: windowElement)

        let endTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = endTime - startTime

        results?[AccessibilityParsedElements.elapsedTime] = "\(elapsedTime)"

        return results
    }

    // MARK: - Private Functions

    //    static func findRootElementsWithAttribute(element: AXUIElement, attribute: CFString, maxDepth: Int) -> [AXUIElement] {
    //        var rootElementsWithAttribute: [AXUIElement] = []
    //
    //        func helper(currentElement: AXUIElement, currentDepth: Int) {
    //            // Check if the current depth exceeds maxDepth
    //            if currentDepth > maxDepth {
    //                return
    //            }
    //
    //            // Check if the element is valid
    //            var elementPid: pid_t = 0
    //            let pidResult = AXUIElementGetPid(currentElement, &elementPid)
    //            if pidResult != .success {
    //                print("Invalid element (cannot get pid). Skipping.")
    //                return
    //            }
    //
    //            // Attempt to get the attribute names
    //            var attributeNamesCFArray: CFArray?
    //            let namesResult = AXUIElementCopyAttributeNames(currentElement, &attributeNamesCFArray)
    //            if namesResult == .success, let namesArray = attributeNamesCFArray as? [String] {
    //                if namesArray.contains(attribute as String) {
    //                    rootElementsWithAttribute.append(currentElement)
    //                } else {
    //                    // Get children only if the current element does not have the attribute
    //                    var childrenValue: CFTypeRef?
    //                    let childrenResult = AXUIElementCopyAttributeValue(currentElement, kAXChildrenAttribute as CFString, &childrenValue)
    //                    if childrenResult == .success, let childrenArray = childrenValue as? [AXUIElement] {
    //                        for child in childrenArray {
    //                            helper(currentElement: child, currentDepth: currentDepth + 1)
    //                        }
    //                    }
    //                }
    //            } else {
    //                print("Failed to get attribute names for element. Skipping. Error: \(namesResult.rawValue)")
    //            }
    //        }
    //
    //        helper(currentElement: element, currentDepth: 0)
    //        return rootElementsWithAttribute
    //    }

}
