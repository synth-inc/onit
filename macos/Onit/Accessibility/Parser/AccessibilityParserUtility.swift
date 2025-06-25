//
//  AccessibilityParserUtility.swift
//  Onit
//
//  Created by Kévin Naudin on 20/01/2025.
//

import AppKit
import ApplicationServices.HIServices

/// Result of parsing an accessibility element
enum AccessibilityParseResult {
    case continueRecursing([String: String]?)
    case stopRecursing([String: String]?)
    
    var results: [String: String]? {
        switch self {
        case .continueRecursing(let results), .stopRecursing(let results):
            return results
        }
    }
    
    var shouldContinue: Bool {
        switch self {
        case .continueRecursing:
            return true
        case .stopRecursing:
            return false
        }
    }
}

/// An utility class helping for parsing Accessibility
class AccessibilityParserUtility {

    /**
     * Perform a parsing logic using `handler` on an `element` and recursively do it on its children
     * Parsing will stop when `maxDepth` is reached or when handler returns `.stopRecursing`
     *
     * - parameter element: `AXUIElement` to parse
     * - parameter maxDepth: Children's depth maximum where the parsing stops
     * - parameter handler: Handler which apply the parsing logic, receives element and current depth. Return `.stopRecursing` to prevent recursing into children of this element.
     */
    static func recursivelyParse(
        element: AXUIElement,
        maxDepth: Int,
        handler: (AXUIElement, Int) -> AccessibilityParseResult
    ) -> [String: String] {
        var results: [String: String] = [:]

        guard let currentScreen = element.getFrame(convertedToGlobalCoordinateSpace: true)?.findScreen() else {
            log.error("Cannot find screen for element")

            return [:]
        }
        
        guard element.pid() != nil else {
            print("Invalid element (cannot get pid). Skipping.")
            
            return [:]
        }

        func helper(currentElement: AXUIElement, currentDepth: Int) {
            // Check if the current depth exceeds maxDepth
            guard currentDepth <= maxDepth else { return }

            // Skip off-screen element
            if let frame = currentElement.getFrame(convertedToGlobalCoordinateSpace: true),
                frame.width <= 0 || frame.height <= 0 || !currentScreen.visibleFrame.intersects(frame) {
                print("Element is off-screen. Skipping.")
                return
            }

            // Apply parsing handler on element and merge results
            let parseResult = handler(currentElement, currentDepth)
            if let result = parseResult.results {
                results.merge(result) { _, new in new }
            }

            // Only recursively parse children if handler didn't return .stopRecursing
            if parseResult.shouldContinue, let children = currentElement.children() {
                for child in children {
                    helper(currentElement: child, currentDepth: currentDepth + 1)
                }
            }
        }

        helper(currentElement: element, currentDepth: 0)

        return results
    }

}
