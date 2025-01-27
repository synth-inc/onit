//
//  WindowHelper.swift
//  Onit
//
//  Created by Kévin Naudin on 22/01/2025.
//

import Foundation
import SwiftUI

enum AccessibilityMode {
    case textfieldMode
    case highlightTopEdgeMode
}

@MainActor
class WindowHelper {
    
    // MARK: - Singleton instance
    
    static let shared = WindowHelper()
    
    // MARK: - Private properties
    
    private var mode: AccessibilityMode = .highlightTopEdgeMode
    
    private let window: NSWindow
    
    // MARK: - Initializers
    
    private init() {
        let hostingController = NSHostingController(rootView: StaticPromptView())
        
        window = NSWindow(contentViewController: hostingController)
        
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    
    // MARK: - Functions
    
    /** Show the open app's shortcut window */
    func show() {
        guard window.isVisible == false else {
            return
        }
        
        adjustWindowToTopRight()
        showWindowWithAnimation()
    }
    
    /** Hide the open app's shortcut window */
    func hide() {
        window.orderOut(nil)
    }
    
    func adjustWindowToTopRight() {
        DispatchQueue.main.async {
            guard let currentScreen = NSScreen.main else {
                print("No main screen found.")
                return
            }

            // Get the window's height (or 75x75 beacuse sometimes it's empty?)
            let windowHeight = max(self.window.frame.height, 75)
            let windowWidth = max(self.window.frame.width, 75)

            // Calculate the new origin for the window to be at the top right corner of the current screen
            let newOriginX = currentScreen.visibleFrame.maxX - (windowWidth - 10)
            let newOriginY = currentScreen.visibleFrame.maxY - (windowHeight + 85)
            
            // Set the window's position to the calculated top right corner
            self.window.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
        }
    }
    
    private func showWindowWithAnimation() {
        DispatchQueue.main.async {
            // Ensure the contentView is layer-backed
            self.window.contentView?.wantsLayer = true

            // Get the contentView's layer
            guard let layer = self.window.contentView?.layer else { return }

            // Set the anchorPoint to the right and adjust the layer's position
            let oldFrame = layer.frame
            layer.anchorPoint = CGPoint(x: 1.0, y: 0.5)
            layer.frame = oldFrame // Reset frame to keep the layer in the same place

            // Set initial state
            self.window.alphaValue = 0.0
            self.window.makeKeyAndOrderFront(nil)

            // Animate the window's alphaValue
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3 // Adjust duration as needed
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.window.animator().alphaValue = 1.0
            }

            // Create a width animation for the layer
            let widthAnimation = CABasicAnimation(keyPath: "bounds.size.width")
            widthAnimation.fromValue = 0.0
            widthAnimation.toValue = oldFrame.size.width
            widthAnimation.duration = 0.3 // Match duration with alphaValue animation
            widthAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

            // Apply the animation to the layer
            layer.add(widthAnimation, forKey: "expandWidth")

            // Set the final bounds to ensure the layer ends up at the correct size
            layer.bounds.size.width = oldFrame.size.width
        }
    }
    
    @MainActor
    func resetPrompt<Content: View>(with newView: Content) {
        // Create a new NSHostingController with the new view
        let newHostingController = NSHostingController(rootView: newView)

        // Assign the new hosting controller to the window
        window.contentViewController = newHostingController

        // If the window is currently visible, bring it to the front again
        if mode == .highlightTopEdgeMode {
            window.orderOut(nil)
        } else {
            adjustWindowToTopRight()
        }

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
