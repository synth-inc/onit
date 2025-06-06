//
//  CaretDebugger.swift
//  Onit
//
//  Created by Kévin Naudin on 06/06/2025.
//

import ApplicationServices
import AppKit
import Foundation

// TODO: KNA - Should be removed after debugging
struct CaretDebugger {
    
    static func debugCaretDetection() -> String {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return "No frontmost application"
        }
        
        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        let appName = frontmostApp.localizedName ?? "Unknown"
        
        var debugInfo = "=== Caret Detection Debug ===\n"
        debugInfo += "App: \(appName)\n"
        debugInfo += "Bundle ID: \(frontmostApp.bundleIdentifier ?? "Unknown")\n\n"
        
        debugInfo += debugMainWindow(appElement)
        debugInfo += debugFocusedElement(appElement)
        debugInfo += debugEnhancedDetection(appElement, appName: appName)
        
        return debugInfo
    }
    
    // MARK: - Private Debug Methods
    
    private static func debugMainWindow(_ appElement: AXUIElement) -> String {
        var info = ""
        
        if let mainWindow = appElement.mainWindow() ?? appElement.focusedWindow() {
            if let windowFrame = mainWindow.getFrame() {
                info += "Window Frame: \(windowFrame)\n"
            }
            info += "Window Role: \(mainWindow.role() ?? "None")\n"
            info += "Window Title: \(mainWindow.title() ?? "None")\n\n"
        }
        
        return info
    }
    
    private static func debugFocusedElement(_ appElement: AXUIElement) -> String {
        var info = ""
        
        if let focusedElement = appElement.findFocusedTextElement() {
            info += "Focused Element Role: \(focusedElement.role() ?? "None")\n"
            info += "Focused Element Value: \(focusedElement.value() ?? "None")\n"
            
            if let elementFrame = focusedElement.getFrame() {
                info += "Focused Element Frame: \(elementFrame)\n"
            }
            
            if let selectedBounds = focusedElement.selectedTextBound() {
                info += "Selected Text Bounds: \(selectedBounds)\n"
            }
        } else {
            info += "No focused text element found\n"
            info += debugAnyFocusedElement(appElement)
        }
        
        return info
    }
    
    private static func debugAnyFocusedElement(_ appElement: AXUIElement) -> String {
        var info = ""
        
        if let anyFocusedElementValue = appElement.attribute(forAttribute: kAXFocusedUIElementAttribute as CFString) {
            let anyFocusedElement = anyFocusedElementValue as! AXUIElement
            info += "Found general focused element: \(anyFocusedElement.role() ?? "Unknown")\n"
            info += "General focused element value: \(anyFocusedElement.value() ?? "None")\n"
            if let frame = anyFocusedElement.getFrame() {
                info += "General focused element frame: \(frame)\n"
            }
        } else {
            info += "No focused element found at all\n"
        }
        
        return info
    }
    
    private static func debugEnhancedDetection(_ appElement: AXUIElement, appName: String) -> String {
        var info = ""
        
        if let focusedElement = appElement.findFocusedTextElement(),
           let caretRect = focusedElement.selectedTextBound() {
            info += "\nDetection Result: \(caretRect)\n"
            let converted = CaretCoordinateConverter.convertToScreenCoordinates(caretRect, fromElement: focusedElement)
            info += "After Coordinate Conversion: \(converted)\n"
        } else {
            info += "\nNo detection result found\n"
        }
        
        return info
    }
} 
