//
//  FocusedElementWorker.swift
//  Onit
//
//  Created by Alex on 13/01/2025.
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
    
    func scanElementHierarchyForFocusedElement(window: AXUIElement) -> AXUIElement? {
        var documentValue: AnyObject?
        let error = AXUIElementCopyAttributeValue(window, kAXDocumentAttribute as CFString, &documentValue)
        
        if error == .success, let document = documentValue {
            if let focusedElement = focusedElementFound(for: document as! AXUIElement) {
                return focusedElement
            }
        }

        return focusedElementFound(in: window, element: window)
    }
    
    // MARK: - Private Functions
    
    private func focusedElementFound(for element: AXUIElement) -> AXUIElement? {
        if let isFocused = element.focused(),
           isFocused {
            return element
        }
        
        return nil
    }
    
    private func focusedElementFound(in focusedWindow: AXUIElement, element: AXUIElement, depth: Int = 0) -> AXUIElement? {
        guard depth < maxSearchDepth else { return nil }
        
        if let children = element.visibleChildren() ?? element.children() {
            for child in children {
                if let focusedElement = focusedElementFound(for: child) {
                    return focusedElement
                }
                if let focusedElement = focusedElementFound(in: focusedWindow, element: child, depth: depth + 1) {
                    return focusedElement
                }
            }
        }
        return nil
    }
}
