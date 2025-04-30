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
        "Xcode": AccessibilityParserXCode(),
        "Calendar": AccessibilityParserCalendar(),
        "Pages": ClipboardParser()
    ]

    // MARK: - Functions

    func getAllTextInElement(windowElement: AXUIElement) async -> [String: String] {
        let startTime = CFAbsoluteTimeGetCurrent()

        let appName = windowElement.parent()?.title() ?? "Unknown"
        let appTitle = windowElement.title() ?? "Unknown"
        let parser = parsers[appName] ?? genericParser

        var results = parser.parse(element: windowElement)

        let endTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = endTime - startTime

        results[AccessibilityParsedElements.applicationName] = appName
        results[AccessibilityParsedElements.applicationTitle] = appTitle
        results[AccessibilityParsedElements.elapsedTime] = "\(elapsedTime)"

        return results
    }
}
