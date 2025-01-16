//
//  AccessibilityReader.swift
//  Onit
//
//  Created by Kévin Naudin on 15/01/2025.
//

import ApplicationServices
import AppKit

/**
 * This class is used for reading accessibility attributes using `Accessibility` API.
 * Starting by the window `AXUIElement`
 *
 */
class AccessibilityReader {
    
    static func getAllTextInElement(appElement: AXUIElement) async -> String? {
        var cumulativeText = ""
        let startTime = CFAbsoluteTimeGetCurrent()
        let (elementsWithText, maxDepth, totalElementsSearched) =
            findAllVisibleElementsWithAttribute(element: appElement,
                                                attributes: AccessibilityReaderConfig.attributes,
                                                maxDepth: AccessibilityReaderConfig.recursiveDepthMax,
                                                cumulativeText: &cumulativeText)
        let endTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = endTime - startTime

        cumulativeText = cumulativeText + "************************ \n\n\n"
        cumulativeText = cumulativeText + "Time taken to find elements with attribute: \(elapsedTime) seconds \n"
        cumulativeText = cumulativeText + "Num searched: \(totalElementsSearched) \n"
        cumulativeText = cumulativeText + "Num found: \(elementsWithText.count) \n"
        cumulativeText = cumulativeText + "Max depth: \(maxDepth) \n"

        for element in elementsWithText {
            if let text = element.value() {
                cumulativeText = cumulativeText + text + " "
            }
        }
        
        return cumulativeText
    }
    
    static func findAllVisibleElementsWithAttribute(element: AXUIElement,
                                                    attributes: [String],
                                                    maxDepth: Int,
                                                    cumulativeText: UnsafeMutablePointer<String>) -> ([AXUIElement], Int, Int) {
        var elementsWithAttribute: [AXUIElement] = []
        var totalElementsSearched = 0
        var maxDepthReached = 0

        guard let currentScreen = NSScreen.main else {
            print("No main screen found.")
            return (elementsWithAttribute, totalElementsSearched, maxDepthReached)
        }
        
        func helper(currentElement: AXUIElement, currentDepth: Int) {
            // Increment the total elements searched
            totalElementsSearched += 1

            // Update the maximum depth reached
            maxDepthReached = max(maxDepthReached, currentDepth)
            
            // Check if the current depth exceeds maxDepth
            guard currentDepth <= maxDepth else { return }
            

            // Check if the element is valid
            var elementPid: pid_t = 0
            if AXUIElementGetPid(currentElement, &elementPid) != .success {
                print("Invalid element (cannot get pid). Skipping.")
                return
            }

            // Check if the element is off-screen
            if let frame = currentElement.frame(),
               (frame.width <= 0 || frame.height <= 0 || !currentScreen.visibleFrame.intersects(frame)) {
                    
                cumulativeText.pointee = cumulativeText.pointee + "Element is off-screen.\n"
                 
                return
            }
            
            for attribute in attributes {
                if let value = currentElement.attribute(forAttribute: attribute as CFString), !"\(value)".isEmpty {
                    cumulativeText.pointee = cumulativeText.pointee + "Value found for \(attribute): \(value)\n"
                    elementsWithAttribute.append(currentElement)
                    // break
                }
            }

            if let visibleChildren = currentElement.children() {
                for child in visibleChildren {
                    helper(currentElement: child, currentDepth: currentDepth + 1)
                }
            }
        }

        helper(currentElement: element, currentDepth: 0)
        return (elementsWithAttribute, maxDepthReached, totalElementsSearched)
    }

    static func findRootElementsWithAttribute(element: AXUIElement, attribute: CFString, maxDepth: Int) -> [AXUIElement] {
        var rootElementsWithAttribute: [AXUIElement] = []

        func helper(currentElement: AXUIElement, currentDepth: Int) {
            // Check if the current depth exceeds maxDepth
            if currentDepth > maxDepth {
                return
            }

            // Check if the element is valid
            var elementPid: pid_t = 0
            let pidResult = AXUIElementGetPid(currentElement, &elementPid)
            if pidResult != .success {
                print("Invalid element (cannot get pid). Skipping.")
                return
            }

            // Attempt to get the attribute names
            var attributeNamesCFArray: CFArray?
            let namesResult = AXUIElementCopyAttributeNames(currentElement, &attributeNamesCFArray)
            if namesResult == .success, let namesArray = attributeNamesCFArray as? [String] {
                if namesArray.contains(attribute as String) {
                    rootElementsWithAttribute.append(currentElement)
                } else {
                    // Get children only if the current element does not have the attribute
                    var childrenValue: CFTypeRef?
                    let childrenResult = AXUIElementCopyAttributeValue(currentElement, kAXChildrenAttribute as CFString, &childrenValue)
                    if childrenResult == .success, let childrenArray = childrenValue as? [AXUIElement] {
                        for child in childrenArray {
                            helper(currentElement: child, currentDepth: currentDepth + 1)
                        }
                    }
                }
            } else {
                print("Failed to get attribute names for element. Skipping. Error: \(namesResult.rawValue)")
            }
        }

        helper(currentElement: element, currentDepth: 0)
        return rootElementsWithAttribute
    }
    
}
