//
//  AppDelegate+Accessibility.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import ApplicationServices
import SwiftUI

enum AccessibilityMode {
    case textfieldMode
    case highlightTopEdgeMode
}

class Accessibility {
    private var mode: AccessibilityMode = .highlightTopEdgeMode

    let kAXFrameAttribute = "AXFrame"

    private var window: NSWindow?

    private var nsObjectObserver: NSObjectProtocol?
    private var observer: AXObserver?
    private var observedElementForSelection: Unmanaged<AXUIElement>?

    private var runLoopSource: CFRunLoopSource?

    private init() { }

    private static let shared = Accessibility()

    static func requestPermissions() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            print("Requesting Accessibility Permissions...")
        } else {
            print("Accessibility Trusted!")
        }
    }

    @MainActor
    static func setupWindow<Content: View>(withView contentView: Content) {
        shared.setupWindow(withView: contentView)
    }

    @MainActor
    private func setupWindow<Content: View>(withView contentView: Content) {
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        self.window = window

        if mode == .highlightTopEdgeMode {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    static func observeActiveApplication() {
        shared.observeActiveApplication()
    }

    private func observeActiveApplication() {
        nsObjectObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let self = self else { return }
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                print("\nApplication activated: \(app.localizedName ?? "Unknown")")
                self.setupObserver(for: app.processIdentifier)
            }
        }
    }

    static func observeFocusChanges() {
        shared.observeFocusChanges()
    }

    func handleAccessibilityNotification(_ notification: String, element: AXUIElement) {
        switch notification {
        case kAXFocusedUIElementChangedNotification as String:
            handleFocusChange(for: element)
        case kAXSelectedTextChangedNotification as String:
            handleSelectionChange(for: element)
        default:
            break
        }
    }

    private func observeFocusChanges() {
        let systemElement = AXUIElementCreateSystemWide()

        var observer: AXObserver?

        let observerCallback: AXObserverCallback = { _, element, notification, refcon in
            let accessibilityInstance = Unmanaged<Accessibility>.fromOpaque(refcon!).takeUnretainedValue()
            print("Received notification: \(notification)")
            accessibilityInstance.handleAccessibilityNotification(notification as String, element: element)
        }

        let result = AXObserverCreate(pid_t(getpid()), observerCallback, &observer)

        if result == .success, let observer = observer {
            self.observer = observer
            let refCon = Unmanaged.passUnretained(self).toOpaque()

            // Observe focused UI element changes
            AXObserverAddNotification(observer, systemElement, kAXFocusedUIElementChangedNotification as CFString, refCon)

            // Retain the run loop source
            let runLoopSource = AXObserverGetRunLoopSource(observer)
            self.runLoopSource = runLoopSource
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

            print("Observer registered for system-wide focus change notifications")
        } else {
            print("Failed to create observer with result: \(result)")
        }
    }

    private func setupObserver(for pid: pid_t) {
        print("Setting up observer for PID: \(pid)")
        let appElement = AXUIElementCreateApplication(pid)

        var observer: AXObserver?

        let observerCallback: AXObserverCallback = { _, element, notification, refcon in
            let accessibilityInstance = Unmanaged<Accessibility>.fromOpaque(refcon!).takeUnretainedValue()
            print("Focus change notification: \(notification)")
            accessibilityInstance.handleAccessibilityNotification(notification as String, element: element)
        }

        let result = AXObserverCreate(pid, observerCallback, &observer)

        if result == .success, let observer = observer {
            self.observer = observer
            let refCon = Unmanaged.passUnretained(self).toOpaque()

            // Register for focused UI element changes
            AXObserverAddNotification(observer, appElement, kAXFocusedUIElementChangedNotification as CFString, refCon)

            // Add the observer to the main run loop
            CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)

            print("Observer registered for PID: \(pid)")

            // Handle initial focus
            handleInitialFocus(for: appElement)
        } else {
            print("Failed to create observer for PID: \(pid) with result: \(result)")
        }
    }

    private func handleInitialFocus(for appElement: AXUIElement) {
        // Retrieve the currently focused UI element within the application
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        if result == .success, let focusedElement = focusedElement {
            print("Successfully retrieved focused UI element within application.")
            if CFGetTypeID(focusedElement) == AXUIElementGetTypeID() {
                let axElement = focusedElement as! AXUIElement
                handleFocusChange(for: axElement)
            } else {
                print("Focused element is not an AXUIElement.")
            }
        } else {
            print("Failed to get focused UI element within application. Error: \(result.rawValue)")
        }
    }

    func handleFocusChange(for focusedElement: AXUIElement) {
        switch mode {
        case .textfieldMode:
            handleTextFieldMode(for: focusedElement)
        case .highlightTopEdgeMode:
            // Remove previous selection observer
            if let previousElement = observedElementForSelection, let observer = observer {
                AXObserverRemoveNotification(observer, previousElement.takeUnretainedValue(), kAXSelectedTextChangedNotification as CFString)
                previousElement.release()
                observedElementForSelection = nil
            }

            guard let observer = observer else {
                print("Observer is nil")
                return
            }

            // Find the text element that supports selection
            let elementToObserve = findElementWithAttribute(element: focusedElement, attribute: kAXSelectedTextRangeAttribute as CFString) ?? focusedElement

            // Retain the element
            let retainedElement = Unmanaged.passRetained(elementToObserve)
            observedElementForSelection = retainedElement

            // Add observer to new element
            let result = AXObserverAddNotification(observer, elementToObserve, kAXSelectedTextChangedNotification as CFString, Unmanaged.passUnretained(self).toOpaque())
            if result == .success {
                print("Added selection changed observer to element.")
            } else {
                print("Failed to add selection changed notification to new element. Error: \(result.rawValue)")
                observedElementForSelection?.release()
                observedElementForSelection = nil
            }

            // Handle initial selection
            handleHighlightTopEdgeMode(elementToObserve)
        }
    }

    func handleTextFieldMode(for focusedElement: AXUIElement) {
        print("Handling focus change...")

        // Get the role of the focused element
        var roleValue: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(focusedElement, kAXRoleAttribute as CFString, &roleValue)
        if roleResult == .success, let role = roleValue as? String {
            print("Focused element role: \(role)")
        } else {
            print("Failed to get role of focused element. Error: \(roleResult.rawValue)")
        }

        // Try to get the frame of the focused element
        var frameValue: CFTypeRef?
        let frameResult = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXFrameAttribute as CFString,
            &frameValue
        )

        if frameResult == .success, let frameValue = frameValue, CFGetTypeID(frameValue) == AXValueGetTypeID() {
            var frame = CGRect.zero

            AXValueGetValue(frameValue as! AXValue, .cgRect, &frame)
            print("Element frame: \(frame)")

            adjustWindowPosition(with: frame)
        } else {
            print("Failed to get frame of focused element. Error: \(frameResult.rawValue)")

            // Attempt to find a text field within the focused element
            if let textFieldElement = findTextFieldInElement(focusedElement) {
                print("Text field found within focused element.")
                moveFloatingWindowToElement(textFieldElement)
            } else {
                print("No text field found within focused element.")
            }
        }
    }

    private func handleHighlightTopEdgeMode(_ focusedElement: AXUIElement) {
        print("Handling highlight in top edge mode...")

        // Get the role of the focused element for debugging
        var roleValue: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(focusedElement, kAXRoleAttribute as CFString, &roleValue)
        if roleResult == .success, let role = roleValue as? String {
            print("Focused element role: \(role)")
        } else {
            print("Failed to get role of focused element. Error: \(roleResult.rawValue)")
        }

        // Try to get the selected text range
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, &value)

        if result == .success {
            let value = value as! AXValue
            // Get the range
            var range = CFRange()
            if AXValueGetValue(value, .cfRange, &range) {
                print("Selected text range: \(range)")

                if range.length > 0 {
                    // Get the bounding rectangle for the selected text
                    var boundingValue: CFTypeRef?
                    let paramResult = AXUIElementCopyParameterizedAttributeValue(
                        focusedElement,
                        kAXBoundsForRangeParameterizedAttribute as CFString,
                        value,
                        &boundingValue
                    )

                    if paramResult == .success {
                        let boundingValue = boundingValue as! AXValue

                        var boundingRect = CGRect.zero
                        if AXValueGetValue(boundingValue, .cgRect, &boundingRect) {
                            print("Bounding rect for selected text: \(boundingRect)")
                            // Adjust the window position based on the bounding rect
                            adjustWindowPosition(with: boundingRect)
                            DispatchQueue.main.async {
                                self.showWindowWithAnimation()
                                print("Window shown at selected text position.")
                            }
                        } else {
                            print("Failed to get CGRect from AXValue.")
                        }
                    } else {
                        print("Failed to get bounding rect for selected text. Error: \(paramResult.rawValue)")
                        // Fallback to hiding the window
                        DispatchQueue.main.async {
                            self.window?.orderOut(nil)
                            print("Window hidden; unable to get bounding rect.")
                        }
                    }
                } else {
                    // Hide the window if there's no selection
                    DispatchQueue.main.async {
                        self.window?.orderOut(nil)
                        print("Window hidden; no selection.")
                    }
                }
            } else {
                print("Failed to get CFRange from AXValue.")
            }
        } else {
            print("Failed to get selected text range. Error: \(result.rawValue)")
            // Attempt to find a child element that has AXSelectedTextRange
            if let textElement = findElementWithAttribute(element: focusedElement, attribute: kAXSelectedTextRangeAttribute as CFString) {
                print("Found child element with AXSelectedTextRange.")
                handleHighlightTopEdgeMode(textElement)
            } else {
                print("No element with AXSelectedTextRange found in focused element.")
            }
        }
    }

    func handleSelectionChange(for element: AXUIElement) {
        guard mode == .highlightTopEdgeMode else { return }
        handleHighlightTopEdgeMode(element)
    }

    private func adjustWindowPosition(with rect: CGRect) {
        DispatchQueue.main.async {
            var adjustedRect = rect

            // Determine which screen contains the rect's origin
            guard let screen = NSScreen.screens.first(where: { $0.frame.contains(adjustedRect.origin) }) else {
                print("No screen contains the rect's origin. Using main screen.")
                guard let screen = NSScreen.main else { return }

                // Adjust the y-coordinate to macOS coordinate system
                adjustedRect.origin.y = screen.frame.maxY - adjustedRect.origin.y

                self.window?.setFrameOrigin(NSPoint(x: adjustedRect.origin.x, y: adjustedRect.origin.y))
                return
            }

            // Use visibleFrame to account for safe areas (menu bar, dock)
            let screenFrame = screen.frame
            let visibleFrame = screen.visibleFrame

            // Adjust the y-coordinate from top-left to bottom-left origin
            adjustedRect.origin.y = screenFrame.maxY - adjustedRect.origin.y

            let windowHeight = self.window?.frame.height ?? 0

            // Calculate positions to place the window above or below the selection
            let positionAbove = adjustedRect.origin.y // Window's bottom edge aligns with selection's top edge
            let positionBelow = adjustedRect.origin.y - adjustedRect.height - windowHeight // Window's top edge aligns with selection's bottom edge

            // Determine if positioning above would cause the window to go off the top of the visible area (menu bar)
            let windowTopEdgeIfAbove = positionAbove + windowHeight

            if windowTopEdgeIfAbove > visibleFrame.maxY {
                // Position the window below the selection, ensuring it doesn't go off-screen
                let windowOriginY = max(positionBelow, visibleFrame.minY)
                self.window?.setFrameOrigin(NSPoint(x: adjustedRect.origin.x, y: windowOriginY))
                print("Window positioned below the selection at: \(NSPoint(x: adjustedRect.origin.x, y: windowOriginY))")
            } else {
                // Keep the current behavior, positioning above the selection
                let windowOriginY = max(positionAbove, visibleFrame.minY)
                self.window?.setFrameOrigin(NSPoint(x: adjustedRect.origin.x, y: windowOriginY))
                print("Window positioned above the selection at: \(NSPoint(x: adjustedRect.origin.x, y: windowOriginY))")
            }
        }
    }

    func moveFloatingWindowToElement(_ element: AXUIElement) {
        var frameValue: CFTypeRef?
        let frameResult = AXUIElementCopyAttributeValue(element, kAXFrameAttribute as CFString, &frameValue)

        if frameResult == .success, let frameValue = frameValue, CFGetTypeID(frameValue) == AXValueGetTypeID() {
            var frame = CGRect.zero

            AXValueGetValue(frameValue as! AXValue, .cgRect, &frame)
            print("Child element frame before adjustment: \(frame)")

            adjustWindowPosition(with: frame)
        } else {
            print("Failed to retrieve the frame of the child element.")
        }
    }

    func findTextFieldInElement(_ element: AXUIElement) -> AXUIElement? {
        var roleValue: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)

        if roleResult == .success, let role = roleValue as? String, role == kAXTextFieldRole {
            return element
        }

        var childrenValue: CFTypeRef?
        let childrenResult = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)

        if childrenResult == .success, let children = childrenValue as? [AXUIElement] {
            for child in children {
                if let textField = findTextFieldInElement(child) {
                    return textField
                }
            }
        }
        return nil
    }

    func findElementWithAttribute(element: AXUIElement, attribute: CFString) -> AXUIElement? {
        var attributeNames: CFArray?
        let result = AXUIElementCopyAttributeNames(element, &attributeNames)
        if result == .success, let attributeNames = attributeNames as? [String] {
            if attributeNames.contains(attribute as String) {
                return element
            }
        }

        var childrenValue: CFTypeRef?
        let childrenResult = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)

        if childrenResult == .success, let children = childrenValue as? [AXUIElement] {
            for child in children {
                if let elementWithAttribute = findElementWithAttribute(element: child, attribute: attribute) {
                    return elementWithAttribute
                }
            }
        }
        return nil
    }

    func showWindowWithAnimation() {
        guard let window = self.window else { return }

        DispatchQueue.main.async {
            // Ensure the contentView is layer-backed
            window.contentView?.wantsLayer = true

            // Get the contentView's layer
            guard let layer = window.contentView?.layer else { return }

            // Set the anchorPoint to the center and adjust the layer's position
            let oldFrame = layer.frame
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            layer.frame = oldFrame // Reset frame to keep the layer in the same place

            // Set initial state
            window.alphaValue = 0.0
            window.makeKeyAndOrderFront(nil)

            // Animate the window's alphaValue
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3 // Adjust duration as needed
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().alphaValue = 1.0
            }

            // Create a scale animation for the layer
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = 0.95
            scaleAnimation.toValue = 1.0
            scaleAnimation.duration = 0.3 // Match duration with alphaValue animation
            scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

            // Apply the animation to the layer
            layer.add(scaleAnimation, forKey: "scaleUp")

            // Set the final transform to ensure the layer ends up at the correct scale
            layer.transform = CATransform3DIdentity
        }
    }
}
