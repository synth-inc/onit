//
//  HighlightHintWindowController.swift
//  Onit
//
//  Created by Kévin Naudin on 22/01/2025.
//

import Foundation
import SwiftUI

enum HighlightHintMode: Codable {
    case textfield
    case topRight
}

@MainActor
class HighlightHintWindowController {
    
    // MARK: - Singleton instance
    
    static let shared = HighlightHintWindowController()
    
    // MARK: - Private properties
    
    private let window: NSWindow
    
    private let staticHostingController = NSHostingController(rootView: StaticPromptView())
    
    private let onitHostingController = NSHostingController(rootView: OnitPromptView())
    
    private var mode: HighlightHintMode? = Preferences.shared.highlightHintMode
    
    private var uiElementBound: CGRect?
    
    // MARK: - Initializers
    
    private init() {
        switch mode {
        case .textfield:
            window = NSWindow(contentViewController: onitHostingController)
        case .topRight:
            window = NSWindow(contentViewController: staticHostingController)
        case nil:
            window = NSWindow()
        }
        
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    
    // MARK: - Functions
    
    /** Show the open app's shortcut window */
    func show(_ bound: CGRect?) {
        uiElementBound = bound
        
        guard mode != nil else { return }
        
        if mode == .topRight && window.isVisible {
            return
        }
        
        adjustWindow()
        showWindowWithAnimation()
    }
    
    /** Hide the open app's shortcut window */
    func hide() {
        window.orderOut(nil)
    }
    
    func changeMode(_ mode: HighlightHintMode?) {
        self.mode = mode
        
        switch mode {
        case .topRight:
            window.contentViewController = staticHostingController
            break
        case .textfield:
            window.contentViewController = onitHostingController
        default:
            window.contentViewController = nil
            return
        }
        
        adjustWindow()
    }
    
    func adjustWindow() {
        DispatchQueue.main.async {
            guard let currentScreen = NSScreen.main else {
                print("No main screen found.")
                return
            }
            
            if self.mode == .topRight {
                
                // Get the window's height (or 75x75 beacuse sometimes it's empty?)
                let windowHeight = max(self.window.frame.height, 75)
                let windowWidth = max(self.window.frame.width, 75)
                
                // Calculate the new origin for the window to be at the top right corner of the current screen
                let newOriginX = currentScreen.visibleFrame.maxX - (windowWidth - 10)
                let newOriginY = currentScreen.visibleFrame.maxY - (windowHeight + 85)
                
                // Set the window's position to the calculated top right corner
                self.window.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
            } else {
                // TODO: KNA - Filter if uiElementBound weird (origin minY = maxY)
                if let bound = self.uiElementBound {
                    let elementScreenY = currentScreen.frame.height - bound.origin.y
                    
                    let newOriginX = bound.origin.x
                    let newOriginY = elementScreenY + 0
                    
                    self.window.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
                } else {
                    // TODO: KNA - What to do
                }
            }
        }
    }
    
    private func showWindowWithAnimation() {
        DispatchQueue.main.async {
            guard let screen = NSScreen.main else { return }
            
            let screenFrame = screen.frame
            var windowFrame = self.window.frame
            
            if self.mode == .topRight {
                // Set initial position (not visible)
                windowFrame.origin.x = screenFrame.maxX
                self.window.setFrame(windowFrame, display: false)
                self.window.alphaValue = 0
                self.window.makeKeyAndOrderFront(nil)
                
                // Set initial position (visible)
                windowFrame.origin.x = screenFrame.maxX - windowFrame.width
                
                // Apply animation
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.15
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    self.window.animator().setFrame(windowFrame, display: true)
                    self.window.animator().alphaValue = 1.0
                }
            } else {
                self.window.alphaValue = 0
                self.window.makeKeyAndOrderFront(nil)
                
                // Apply animation
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.15
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    self.window.animator().alphaValue = 1.0
                }
            }
        }
    }
    
    func shortcutChanges(empty: Bool) {
        guard !empty else {
            // hide()
            print("Prompt hide")
            return
        }
        
//        let hostingController = mode == .topRight ?
//            NSHostingController(rootView: StaticPromptView()) :
//            NSHostingController(rootView: OnitPromptView())
//
//        window.contentViewController = hostingController

        // window.orderFront(nil)
        // adjustWindow()
        print("Prompt reset with new view content.")
    }
    
    func insertText(_ text: String) {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))

        // Get the system-wide element
        let systemElement = AXUIElementCreateSystemWide()

        // Get the focused UI element
        var focusedElementRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemElement, kAXFocusedUIElementAttribute as CFString, &focusedElementRef)

        guard result == .success else {
            print("Failed to get focused UI element. Error: \(result.rawValue)")
            return
        }

        let element = focusedElementRef as! AXUIElement

        // Check if the element is valid
        var elementPid: pid_t = 0
        let pidResult = AXUIElementGetPid(element, &elementPid)
        if pidResult != .success {
            print("Invalid focused element (cannot get pid). Skipping.")
            return
        }

        // Proceed with inserting text into 'element'
        // Check if the element supports kAXValueAttribute and it's settable
        var isSettable: DarwinBoolean = false
        let isSettableResult = AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &isSettable)

        // TODO TIM - I don't think this is going to work in many situations, there's no guarentee that "value" settable thing will be the focused element.
        // I think we probably have to traverse the children of the focused element until we find one where the selectedText matches the currently selected text.
        // Even that will get pretty messed up if the selection has changed.
        
        
        if isSettableResult == .success && isSettable.boolValue {
            // Retrieve the current value
            var valueRef: CFTypeRef?
            let valueResult = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef)

            if valueResult == .success, let currentValue = valueRef as? String {
                // Get the selected text range
                var selectedRangeRef: CFTypeRef?
                let rangeResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedRangeRef)

                if rangeResult == .success {
                    let selectedRangeValue = selectedRangeRef as! AXValue

                    // Get the range
                    var range = CFRange()
                    if AXValueGetValue(selectedRangeValue, .cfRange, &range) {
                        // Modify the text by replacing the selected range with the new text
                        let nsCurrentValue = currentValue as NSString
                        let newText = nsCurrentValue.replacingCharacters(in: NSRange(location: range.location, length: range.length), with: text)

                        // Set the new value
                        let setResult = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, newText as CFTypeRef)

                        if setResult == .success {
                            print("Text inserted successfully.")
                        } else {
                            print("Failed to set value: \(setResult.rawValue)")
                        }
                    } else {
                        print("Failed to get CFRange from AXValue.")
                    }
                } else {
                    print("Failed to get selected text range. Error: \(rangeResult.rawValue)")
                }
            } else {
                print("Failed to get current value. Error: \(valueResult.rawValue)")
            }
        } else {
            print("Element's value attribute is not settable or failed to check. Error: \(isSettableResult.rawValue)")
        }
    }
}
