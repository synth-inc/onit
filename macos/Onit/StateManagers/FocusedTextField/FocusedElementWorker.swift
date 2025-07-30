//
//  FocusedTextFieldWorker.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/29/25.
//

import ApplicationServices
import Foundation

@MainActor
final class FocusedElementWorker  {

    // MARK: - Singleton

    static let shared = FocusedElementWorker()

    // MARK: - Properties

    private let maxSearchDepth = 100

    // MARK: - Private initializer

    private init() { }

    // MARK: - Public Functions

    func scanElementHierarchyForAllFocusedElements(window: AXUIElement) -> [AXUIElement] {
        var focusedElements: [AXUIElement] = []

        var documentValue: AnyObject?
        let error = AXUIElementCopyAttributeValue(window, kAXDocumentAttribute as CFString, &documentValue)

        if error == .success, let document = documentValue {
            if let focusedElement = checkIfElementFocused(document as! AXUIElement) {
                focusedElements.append(focusedElement)
            }
        }

        let windowFocusedElements = findAllFocusedElements(in: window, element: window)
        focusedElements.append(contentsOf: windowFocusedElements)

        return focusedElements
    }

    // MARK: - Private Functions

    private func checkIfElementFocused(_ element: AXUIElement) -> AXUIElement? {
        if let isFocused = element.focused(),
           isFocused {
            return element
        }

        return nil
    }

    private func findAllFocusedElements(in focusedWindow: AXUIElement, element: AXUIElement, depth: Int = 0) -> [AXUIElement] {
        guard depth < maxSearchDepth else { return [] }

        var focusedElements: [AXUIElement] = []

        // Check if current element is focused
        if let focusedElement = checkIfElementFocused(element) {
            focusedElements.append(focusedElement)
        }

        // Continue searching children regardless of whether current element is focused
        if let children = element.visibleChildren() ?? element.children() {
            for child in children {
                let childFocusedElements = findAllFocusedElements(in: focusedWindow, element: child, depth: depth + 1)
                focusedElements.append(contentsOf: childFocusedElements)
            }
        }

        return focusedElements
    }
}
