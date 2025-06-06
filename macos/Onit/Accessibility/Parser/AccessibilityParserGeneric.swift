//
//  AccessibilityParserGeneric.swift
//  Onit
//
//  Created by Kévin Naudin on 20/01/2025.
//

import ApplicationServices.HIServices.AXUIElement
import Foundation

/// Generic  implementation of the ``AccessibilityParserLogic``
class AccessibilityParserGeneric: AccessibilityParserBase {

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
            
            if let value = element.value(), !value.isEmpty {
                screen += "\(value) "
            }

            return nil
        }

        result[AccessibilityParsedElements.screen] = screen

        return result
    }
    
    override func parse(element: AXUIElement, includeBoundingBoxes: Bool) -> ([String: String], [TextBoundingBox]?) {
        var result: [String: String] = [:]
        var screen: String = ""
        var highlightedTextFound = false
        var boundingBoxes: [TextBoundingBox] = []
        
        _ = AccessibilityParserUtility.recursivelyParse(
            element: element,
            maxDepth: AccessibilityParserConfig.recursiveDepthMax
        ) { element in
            
            if !highlightedTextFound {
                let (parentResult, parentBoundingBoxes) = super.parse(element: element, includeBoundingBoxes: includeBoundingBoxes)
                
                if !parentResult.isEmpty {
                    highlightedTextFound = true
                    result.merge(parentResult) { _, new in new }
                    
                    if includeBoundingBoxes, let boxes = parentBoundingBoxes {
                        boundingBoxes.append(contentsOf: boxes)
                    }
                }
            }
            
            if let value = element.value(), !value.isEmpty {
                screen += "\(value) "
                
                if includeBoundingBoxes, let frame = element.getFrame() {
                    let textBoundingBox = TextBoundingBox(
                        text: value,
                        boundingBox: frame,
                        elementRole: element.role(),
                        elementDescription: element.description()
                    )
                    boundingBoxes.append(textBoundingBox)
                }
            }

            return nil
        }

        result[AccessibilityParsedElements.screen] = screen

        return (result, includeBoundingBoxes ? boundingBoxes : nil)
    }
}
