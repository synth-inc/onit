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
        "Pages": ClipboardParser(),
        "Messages": AccessibilityParserMessages()
    ]

    // MARK: - Functions
    func getAllTextInElement(windowElement: AXUIElement, includeBoundingBoxes: Bool = false) async throws -> ([String: String], [TextBoundingBox]?) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let appName = windowElement.parent()?.title() ?? "Unknown"
        let appTitle = windowElement.title() ?? "Unknown"
        let parser = parsers[appName] ?? genericParser
        
        return try await withThrowingTaskGroup(of: ([String: String], [TextBoundingBox]?).self) { group in
            // Using `@Sendable` here is okay, because we're allocating all operations to a single thread (main).
            group.addTask { @MainActor @Sendable in
                let startTime = CFAbsoluteTimeGetCurrent()


                var (results, boundingBoxes) = await parser.parse(element: windowElement, includeBoundingBoxes: includeBoundingBoxes)

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
