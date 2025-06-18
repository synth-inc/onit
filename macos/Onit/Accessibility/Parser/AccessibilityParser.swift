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

    func getAllTextInElement(windowElement: AXUIElement) async throws -> [String: String] {
        let appName = windowElement.parent()?.title() ?? "Unknown"
        let appTitle = windowElement.title() ?? "Unknown"
        let parser = parsers[appName] ?? genericParser
        
        return try await withThrowingTaskGroup(of: [String: String].self) { group in
            group.addTask { @MainActor in
                let startTime = CFAbsoluteTimeGetCurrent()

                var results = parser.parse(element: windowElement)

                let endTime = CFAbsoluteTimeGetCurrent()
                let elapsedTime = endTime - startTime

                results[AccessibilityParsedElements.applicationName] = appName
                results[AccessibilityParsedElements.applicationTitle] = appTitle
                results[AccessibilityParsedElements.elapsedTime] = "\(elapsedTime)"

                return results
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 second timeout
                throw NSError(domain: "AccessibilityParsingTimeout", code: 1, userInfo: nil)
            }
            
            let firstCompleted = try await group.next()!
            group.cancelAll()
            return firstCompleted
        }
    }
}
