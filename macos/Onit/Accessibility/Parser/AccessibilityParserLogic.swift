//
//  AccessibilityParserLogic.swift
//  Onit
//
//  Created by Kévin Naudin on 20/01/2025.
//

import ApplicationServices.HIServices.AXUIElement
import Foundation

/// Logic used to parse the Accessibility DOM using `AXUIElement`
protocol AccessibilityParserLogic {
    
    /**
     * Parse the `AXUIElement` to retrieve desired data
     * - parameter element: `AXUIElement` to parse
     * - returns: A dictionary of data retrieved
     */
    func parse(element: AXUIElement) -> [String: String]
    
    /**
     * Parse the `AXUIElement` to retrieve desired data with optional bounding boxes
     * - parameter element: `AXUIElement` to parse
     * - parameter includeBoundingBoxes: Whether to include bounding box information
     * - returns: A tuple containing the parsed data dictionary and optional bounding box array
     */
    func parse(element: AXUIElement, includeBoundingBoxes: Bool) -> ([String: String], [TextBoundingBox]?)
}

extension AccessibilityParserLogic {
    func parse(element: AXUIElement, includeBoundingBoxes: Bool) -> ([String: String], [TextBoundingBox]?) {
        let result = parse(element: element)
        return (result, includeBoundingBoxes ? [] : nil)
    }
}
