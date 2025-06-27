//
//  CaretPositionManager.swift
//  Onit
//
//  Created by Kévin Naudin on 06/06/2025.
//

import ApplicationServices
import Foundation
import SwiftUI

@MainActor
class CaretPositionManager: ObservableObject {
    
    // MARK: - Singleton instance
    
    static let shared = CaretPositionManager()
    
    // MARK: - Published properties
    
    @Published private(set) var currentCaretPosition: CGRect?
    @Published private(set) var currentApplication: String?
    @Published private(set) var currentElement: AXUIElement?
    @Published private(set) var isCaretVisible: Bool = false
    
    // MARK: - Private properties
    
    private var lastCaretPosition: CGRect?
    
    // MARK: - Delegates
    
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
    // MARK: - Private initialization
    
    private init() { }
    
    // MARK: - Delegate Management
    
    func addDelegate(_ delegate: CaretPositionDelegate) {
        delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate: CaretPositionDelegate) {
        delegates.remove(delegate)
    }
    
    private func notifyDelegates(_ notification: (CaretPositionDelegate) -> Void) {
        for case let delegate as CaretPositionDelegate in delegates.allObjects {
            notification(delegate)
        }
    }
    
    // MARK: - Notification-Based Caret Tracking
    
    func updateCaretPosition(for element: AXUIElement) {
        guard let caretRect = element.selectedTextBound() else {
            updateCaretLost()
            return
        }
        
        let isValidCaretRect = caretRect.width > 0 && caretRect.height > 0
        let baseCaretRect: CGRect
        
        if isValidCaretRect {
            baseCaretRect = caretRect
        } else {
            baseCaretRect = calculateCaretFromElement(element, originalRect: caretRect)
        }
        
        let adjustedCaretRect = adjustCaretToElementBounds(baseCaretRect, element: element)
        let screenCaretRect = convertToScreenCoordinates(adjustedCaretRect, fromElement: element)
        let appName = element.appName() ?? "Unknown"
        
        processCaretPosition(screenCaretRect, element: element, app: appName)
    }
    
    func updateCaretLost() {
        if isCaretVisible {
            isCaretVisible = false
            currentCaretPosition = nil
            currentElement = nil
            
            notifyDelegates { delegate in
                delegate.caretDidDisappear()
            }
        }
    }
    
    // MARK: - Private Functions
    
    private func adjustCaretToElementBounds(_ caretRect: CGRect, element: AXUIElement) -> CGRect {
        guard let elementFrame = element.firstGroupParent()?.getFrame() ?? element.getFrame() else {
            return caretRect
        }
        
        return CGRect(
            x: elementFrame.origin.x,
            y: caretRect.origin.y,
            width: elementFrame.width,
            height: caretRect.height
        )
    }
    
    private func calculateCaretFromElement(_ element: AXUIElement, originalRect: CGRect) -> CGRect {
        guard let elementFrame = element.getFrame() else {
            return CGRect(x: originalRect.origin.x, y: originalRect.origin.y, width: 2, height: 16)
        }
        
        let positionSeemsReasonable = originalRect.origin.x >= elementFrame.origin.x - 50 &&
                                      originalRect.origin.x <= elementFrame.maxX + 50 &&
                                      originalRect.origin.y >= elementFrame.origin.y - 50 &&
                                      originalRect.origin.y <= elementFrame.maxY + 50
        
        if positionSeemsReasonable {
            return CGRect(
                x: originalRect.origin.x,
                y: originalRect.origin.y,
                width: max(originalRect.width, 2),
                height: max(originalRect.height, 16)
            )
        }
        
        let caretX = elementFrame.origin.x
        let caretY = elementFrame.origin.y
        
        return CGRect(x: caretX, y: caretY, width: 2, height: 16)
    }
    
    private func convertToScreenCoordinates(_ rect: CGRect, fromElement element: AXUIElement) -> CGRect {
        let screenRect = centerCaretCoordinates(rect)
        
        return convertAccessibilityToMacOSCoordinates(screenRect)
    }
    
    private func centerCaretCoordinates(_ rect: CGRect) -> CGRect {
        let centeredY = rect.height > 0 ? rect.origin.y + (rect.height / 2) : rect.origin.y
        
        return CGRect(
            x: rect.origin.x,
            y: centeredY,
            width: max(rect.width, 2),
            height: max(rect.height, 20)
        )
    }
    
    private func convertAccessibilityToMacOSCoordinates(_ rect: CGRect) -> CGRect {
        guard let mainScreen = NSScreen.primary else {
            return rect
        }
        
        let screenHeight = mainScreen.frame.height
        let convertedY = screenHeight - rect.origin.y - rect.height
        
        return CGRect(
            x: rect.origin.x,
            y: convertedY,
            width: rect.width,
            height: rect.height
        )
    }
    
    private func processCaretPosition(_ position: CGRect, element: AXUIElement, app: String) {
        let hasChanged = lastCaretPosition != position
        
        currentCaretPosition = position
        currentApplication = app
        currentElement = element
        isCaretVisible = true
        lastCaretPosition = position
        
        if hasChanged {
            notifyDelegates { delegate in
                delegate.caretPositionDidChange(position, in: app, element: element)
            }
        }
        
        notifyDelegates { delegate in
            delegate.caretPositionDidUpdate(position, in: app, element: element)
        }
    }
}

// MARK: - CaretPositionDelegate Protocol

@MainActor
protocol CaretPositionDelegate: AnyObject {
    func caretPositionDidChange(_ position: CGRect, in application: String, element: AXUIElement)
    func caretPositionDidUpdate(_ position: CGRect, in application: String, element: AXUIElement)
    func caretDidDisappear()
} 
