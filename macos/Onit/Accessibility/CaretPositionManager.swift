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
            handleCaretLost()
            return
        }
        
        let isValidCaretRect = caretRect.width > 0 && caretRect.height > 0
        let finalCaretRect: CGRect
        
        if isValidCaretRect {
            finalCaretRect = caretRect
        } else {
            finalCaretRect = calculateCaretFromElement(element, originalRect: caretRect)
        }
        
        let screenCaretRect = CaretCoordinateConverter.convertToScreenCoordinates(finalCaretRect, fromElement: element)
        let appName = element.appName() ?? "Unknown"
        
        processCaretPosition(screenCaretRect, element: element, app: appName)
    }
    
    // TODO: KNA - Should be removed after debugging
    func debugCaretDetection() -> String {
        return CaretDebugger.debugCaretDetection()
    }
    
    // MARK: - Private Functions
    
    private func calculateCaretFromElement(_ element: AXUIElement, originalRect: CGRect) -> CGRect {
        guard let elementFrame = element.getFrame() else {
            return CGRect(x: originalRect.origin.x, y: originalRect.origin.y, width: 2, height: 16)
        }
        
        let positionSeamsReasonable = originalRect.origin.x >= elementFrame.origin.x - 50 &&
                                     originalRect.origin.x <= elementFrame.maxX + 50 &&
                                     originalRect.origin.y >= elementFrame.origin.y - 50 &&
                                     originalRect.origin.y <= elementFrame.maxY + 50
        
        if positionSeamsReasonable {
            return CGRect(
                x: originalRect.origin.x,
                y: originalRect.origin.y,
                width: max(originalRect.width, 2),
                height: max(originalRect.height, 16)
            )
        }
        
        let value = element.value() ?? ""
        let textLength = value.count
        let caretX: CGFloat
        
        if textLength > 0 {
            // Estimate caret position based on text length (rough approximation)
            let charWidth: CGFloat = 6 // Average character width
            let estimatedTextWidth = min(CGFloat(textLength) * charWidth, elementFrame.width - 10)
            caretX = elementFrame.origin.x + 5 + estimatedTextWidth // 5px padding from left
        } else {
            caretX = elementFrame.origin.x + 5 // Start with small padding
        }
        
        let caretY = elementFrame.origin.y + (elementFrame.height / 2) - 8
        
        return CGRect(x: caretX, y: caretY, width: 2, height: 16)
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
    
    private func handleCaretLost() {
        if isCaretVisible {
            isCaretVisible = false
            currentCaretPosition = nil
            currentElement = nil
            
            notifyDelegates { delegate in
                delegate.caretDidDisappear()
            }
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
