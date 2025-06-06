//
//  AccessibilityParser.swift
//  Onit
//
//  Created by Kévin Naudin on 15/01/2025.
//

import AppKit
import ApplicationServices
import Foundation

/// This class is used for parsing accessibility attributes using `Accessibility` API.
/// Starting by the root `AXUIElement`
@MainActor
class AccessibilityParser {

    static let shared = AccessibilityParser()

    private let genericParser = AccessibilityParserGeneric()
    private let parsers: [String: AccessibilityParserLogic] = [
        "Xcode": AccessibilityParserXCode(),
        "Calendar": AccessibilityParserCalendar(),
        "Pages": ClipboardParser()
    ]

    // MARK: - Functions

    func getAllTextInElement(windowElement: AXUIElement) async -> [String: String] {
        let (results, _) = await getAllTextInElement(windowElement: windowElement, includeBoundingBoxes: false)
        return results
    }
    
    func getAllTextInElement(windowElement: AXUIElement, includeBoundingBoxes: Bool) async -> ([String: String], [TextBoundingBox]?) {
        let startTime = CFAbsoluteTimeGetCurrent()

        let appName = windowElement.parent()?.title() ?? "Unknown"
        let appTitle = windowElement.title() ?? "Unknown"
        let parser = parsers[appName] ?? genericParser

        var (results, boundingBoxes) = parser.parse(element: windowElement, includeBoundingBoxes: includeBoundingBoxes)

        if includeBoundingBoxes, let boxes = boundingBoxes, let windowFrame = windowElement.getFrame() {
            let normalizedBoxes = boxes.map { box in
                let normalizedFrame = CGRect(
                    x: box.boundingBox.origin.x - windowFrame.origin.x,
                    y: box.boundingBox.origin.y - windowFrame.origin.y,
                    width: box.boundingBox.width,
                    height: box.boundingBox.height
                )
                
                return TextBoundingBox(
                    text: box.text,
                    boundingBox: normalizedFrame,
                    elementRole: box.elementRole,
                    elementDescription: box.elementDescription
                )
            }
            boundingBoxes = normalizedBoxes
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = endTime - startTime

        results[AccessibilityParsedElements.applicationName] = appName
        results[AccessibilityParsedElements.applicationTitle] = appTitle
        results[AccessibilityParsedElements.elapsedTime] = "\(elapsedTime)"

        return (results, boundingBoxes)
    }
}
