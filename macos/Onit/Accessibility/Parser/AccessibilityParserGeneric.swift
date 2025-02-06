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

    //        let biggestElement = findElementWithBiggestArea(appElement: element, result: &result)
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

  // MARK: - Private functions

  /**
     * Find recursively the biggest `AXUIElement` based on its frame
     * Skip the application and window roles
     */
  func findElementWithBiggestArea(appElement: AXUIElement, result: inout [String: String])
    -> AXUIElement
  {
    var biggestElement: AXUIElement?
    var biggestFrame: CGRect?

    _ = AccessibilityParserUtility.recursivelyParse(
      element: appElement,
      maxDepth: Config.recursiveDepthMax
    ) { element in

      if let parentResult = super.parse(element: element) {
        result.merge(parentResult) { _, new in new }
      }

      // TODO: KNA - Change the subrole
      guard let frame = element.frame(), let subrole = element.subrole() else { return nil }
      guard subrole == kAXContentListSubrole else { return nil }

      if let biggestFrameTmp = biggestFrame {
        if biggestFrameTmp.width * biggestFrameTmp.height < frame.width * frame.height {
          print("2/ biggest element found subrole \(subrole) \(frame.size)")
          biggestFrame = frame
          biggestElement = element
        }
      } else {
        print("1/ biggest element found subrole \(subrole) \(frame.size)")
        biggestFrame = frame
        biggestElement = element
      }

      return nil
    }

    return biggestElement ?? appElement
  }
}
