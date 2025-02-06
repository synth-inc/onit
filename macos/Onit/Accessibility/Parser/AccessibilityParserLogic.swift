//
//  AccessibilityParserLogic.swift
//  Onit
//
//  Created by Kévin Naudin on 20/01/2025.
//

import ApplicationServices.HIServices.AXUIElement

/// Logic used to parse the Accessibility DOM using `AXUIElement`
protocol AccessibilityParserLogic {

  /**
     * Parse the `AXUIElement` to retrieve desired data
     * - parameter appElement: `AXUIElement` to parse
     * - returns: An optional dictionnary of data retrieved
     */
  func parse(element: AXUIElement) -> [String: String]?
}
