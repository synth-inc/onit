//  AppDelegate+Accessibility.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import ApplicationServices
import SwiftUI
import Combine

enum AccessibilityMode {
    case textfieldMode
    case highlightTopEdgeMode
}

#if !targetEnvironment(simulator)
class Accessibility {
    var selectedText: String?
    var currentSource: String?
    var selectedSource: String?

    static var input: Input? {
        guard let text = shared.selectedText else { return nil }
        return .init(selectedText: text, application: shared.selectedSource)
    }

    private var mode: AccessibilityMode = .highlightTopEdgeMode

    let kAXFrameAttribute = "AXFrame"
    let kAXBoundsChangedNotification = "AXBoundsChanged"

    private var window: NSWindow?

    private var nsObjectObserver: NSObjectProtocol?
    private var observer: AXObserver?
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

    static var trusted: Bool {
        AXIsProcessTrusted()
    }

    @MainActor
    static func resetPrompt<Content: View>(with newView: Content) {
        shared.resetPrompt(with: newView)
    }

    @MainActor
    private func resetPrompt<Content: View>(with newView: Content) {
        guard let window = self.window else {
            print("No window available to reset.")
            return
        }

        // Create a new NSHostingController with the new view
        let newHostingController = NSHostingController(rootView: newView)

        // Assign the new hosting controller to the window
        window.contentViewController = newHostingController

        // If the window is currently visible, bring it to the front again
        if mode == .highlightTopEdgeMode {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
        }

        print("Prompt reset with new view content.")
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
        DispatchQueue.main.async {
            shared.observeActiveApplication()
        }
    }

    private func observeActiveApplication() {
        let notificationCenter = NSWorkspace.shared.notificationCenter

        // Observe when any application is activated
        nsObjectObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                    // Skip if the activated app is our own app
                    if app.processIdentifier == getpid() {
                        print("Ignoring activation of our own app.")
                        return
                    }
                    print("\nApplication activated: \(app.localizedName ?? "Unknown")")
                    self.currentSource = app.localizedName
                    self.setupObserver(for: app.processIdentifier)
                }

                // Handle app activation
                self.handleAppActivation()
            }
        }

        // Observe when any application is deactivated
        notificationCenter.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                    print("\nApplication deactivated: \(app.localizedName ?? "Unknown")")
                }

                // Handle app deactivation
                self.handleAppDeactivation()
            }
        }
    }

    private func handleAppDeactivation() {
        DispatchQueue.main.async {
            self.window?.orderOut(nil)
            print("Window hidden; application deactivated.")
        }
    }

    private func handleAppActivation() {
        // Check if there's an existing text selection
        if let focusedApp = NSWorkspace.shared.frontmostApplication, focusedApp.processIdentifier != getpid() {
            let pid = focusedApp.processIdentifier
            let appElement = AXUIElementCreateApplication(pid)
            handleInitialFocus(for: appElement)
        } else {
            print("Ignoring handleAppActivation for our own app.")
        }
    }

    static func observeFocusChanges() {
        shared.observeFocusChanges()
    }

    func handleAccessibilityNotification(_ notification: String, element: AXUIElement) {
        dispatchPrecondition(condition: .onQueue(.main))

        // Check if the notification comes from our own process
        var elementPid: pid_t = 0
        let pidResult = AXUIElementGetPid(element, &elementPid)
        if pidResult == .success {
            if elementPid == getpid() {
                print("Ignoring notification from our own process.")
                return
            }
        } else {
            print("Failed to get pid of element. Error: \(pidResult.rawValue)")
        }

        switch notification {
        case kAXFocusedUIElementChangedNotification:
            handleFocusChange(for: element)
        case kAXSelectedTextChangedNotification:
            handleSelectionChange(for: element)
        case kAXBoundsChangedNotification:
            handleBoundsChanged(for: element)
        case kAXValueChangedNotification:
            handleValueChanged(for: element)
        default:
            break
        }
    }

    func handleValueChanged(for element: AXUIElement) {
        print("Handling value changed...")

        // Re-fetch the bounding rectangle for the selected text
        handleHighlightTopEdgeMode(element, shouldAnimate: false)
    }

    func handleBoundsChanged(for element: AXUIElement) {
        print("Handling bounds changed...")

        // Re-fetch the bounding rectangle for the selected text
        handleHighlightTopEdgeMode(element, shouldAnimate: false)
    }

    private func observeFocusChanges() {
        let systemElement = AXUIElementCreateSystemWide()

        var observer: AXObserver?

        let observerCallback: AXObserverCallback = { _, element, notification, refcon in
            // Dispatch to main thread immediately
            DispatchQueue.main.async {
                let accessibilityInstance = Unmanaged<Accessibility>.fromOpaque(refcon!).takeUnretainedValue()
                accessibilityInstance.handleAccessibilityNotification(notification as String, element: element)
            }
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
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.setupObserver(for: pid)
            }
            return
        }
        // Skip if the PID is our own process
        if pid == getpid() {
            print("Not setting up observer for our own process.")
            return
        }
        print("Setting up observer for PID: \(pid)")
        let appElement = AXUIElementCreateApplication(pid)

        var observer: AXObserver?

        let observerCallback: AXObserverCallback = { _, element, notification, refcon in
            // Dispatch to main thread immediately
            DispatchQueue.main.async {
                let accessibilityInstance = Unmanaged<Accessibility>.fromOpaque(refcon!).takeUnretainedValue()
                accessibilityInstance.handleAccessibilityNotification(notification as String, element: element)
            }
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
                handleFocusChange(for: axElement, shouldAnimate: false)
            } else {
                print("Focused element is not an AXUIElement.")
            }
        } else {
            print("Failed to get focused UI element within application. Error: \(result.rawValue)")
        }
    }

    func handleFocusChange(for focusedElement: AXUIElement, shouldAnimate: Bool = true) {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))

        // Check if the focused element is valid
        var elementPid: pid_t = 0
        let pidResult = AXUIElementGetPid(focusedElement, &elementPid)
        if pidResult != .success {
            print("Invalid focused element (cannot get pid). Skipping.")
            return
        }
        if elementPid == getpid() {
            print("Ignoring focus change from our own process.")
            return
        }

        switch mode {
        case .textfieldMode:
            handleTextFieldMode(for: focusedElement)
        case .highlightTopEdgeMode:
            guard let observer = observer else {
                print("Observer is nil")
                return
            }

            // Find the text element that supports selection
            if let elementToObserve = findElementWithAttribute(element: focusedElement, attribute: kAXSelectedTextRangeAttribute as CFString) {

                let refCon = Unmanaged.passUnretained(self).toOpaque()

                // Add observer to new element
                let result1 = AXObserverAddNotification(observer, elementToObserve, kAXSelectedTextChangedNotification as CFString, refCon)
                let result2 = AXObserverAddNotification(observer, elementToObserve, kAXBoundsChangedNotification as CFString, refCon)

                if result1 == .success && result2 == .success {
                    print("Added selection and bounds changed observers to element.")
                } else {
                    print("Failed to add observers. Errors: \(result1.rawValue), \(result2.rawValue)")
                }

                // Store the selected text
                selectedText = getSelectedText(from: elementToObserve)

                // Handle initial selection
                handleHighlightTopEdgeMode(elementToObserve, shouldAnimate: shouldAnimate)
            } else {
                print("No element with AXSelectedTextRange found.")
            }
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

    func handleHighlightTopEdgeMode(_ focusedElement: AXUIElement, shouldAnimate: Bool = true) {
        print("Handling highlight in top edge mode...")
        dispatchPrecondition(condition: .onQueue(.main))

        // Check if the focused element is valid
        var elementPid: pid_t = 0
        let pidResult = AXUIElementGetPid(focusedElement, &elementPid)
        if pidResult != .success {
            print("Invalid element (cannot get pid). Skipping.")
            return
        }

        // Check if the element supports kAXSelectedTextRangeAttribute
        var attributeNamesCFArray: CFArray?
        let namesResult = AXUIElementCopyAttributeNames(focusedElement, &attributeNamesCFArray)
        if namesResult == .success {
            let attributeNames = attributeNamesCFArray as! [String]
            if attributeNames.contains(kAXSelectedTextRangeAttribute as String) {
                // Proceed to get the selected text range
                var valueRef: CFTypeRef?
                let result = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, &valueRef)
                if result != .success {
                    print("Failed to get selected text range. Error: \(result.rawValue)")
                    return
                }
                let value = valueRef as! AXValue

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
                                if shouldAnimate {
                                    self.showWindowWithAnimation()
                                    print("Window shown at selected text position with animation.")
                                } else {
                                    self.showWindowWithoutAnimation()
                                    print("Window shown at selected text position without animation.")
                                }
                            } else {
                                print("Failed to get CGRect from AXValue.")
                            }
                        } else {
                            print("Failed to get bounding rect for selected text. Error: \(paramResult.rawValue)")
                            // Fallback to hiding the window
                            self.window?.orderOut(nil)
                            print("Window hidden; unable to get bounding rect.")
                        }
                    } else {
                        // Hide the window if there's no selection
                        self.window?.orderOut(nil)
                        print("Window hidden; no selection.")
                    }
                } else {
                    print("Failed to get CFRange from AXValue.")
                }
            } else {
                print("Element does not support kAXSelectedTextRangeAttribute.")
                // Attempt to find a child element that does
                if let textElement = findElementWithAttribute(element: focusedElement, attribute: kAXSelectedTextRangeAttribute as CFString) {
                    print("Found child element with AXSelectedTextRange.")
                    handleHighlightTopEdgeMode(textElement)
                } else {
                    print("No element with AXSelectedTextRange found in focused element.")
                }
            }
        } else {
            print("Failed to get attribute names. Error: \(namesResult.rawValue)")
            return
        }
    }

    func getSelectedText(from focusedElement: AXUIElement) -> String? {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))

        // 1. Get the selected text range attribute
        var selectedRangeValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, &selectedRangeValue)

        guard result == .success else {
            print("Failed to get the selected text range. Error: \(result.rawValue)")
            return nil
        }

        let rangeValue = selectedRangeValue as! AXValue

        // 2. Extract the range
        var selectedRange = CFRange()
        if !AXValueGetValue(rangeValue, .cfRange, &selectedRange) {
            print("Failed to extract CFRange from AXValue.")
            return nil
        }
        print("Selected text range: \(selectedRange)")

        // 3. Use AXStringForRangeParameterizedAttribute to get the text for the range
        var selectedTextValue: CFTypeRef?
        let textResult = AXUIElementCopyParameterizedAttributeValue(
            focusedElement,
            kAXStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &selectedTextValue
        )

        if textResult == .success, let selectedText = selectedTextValue as? String, !selectedText.isEmpty {
            print("Selected text: \(selectedText)")
            self.selectedSource = currentSource
            return selectedText
        } else {
            print("Failed to get the selected text. Error: \(textResult.rawValue)")
            self.selectedSource = nil
            return nil
        }
    }

    func showWindowWithoutAnimation() {
        guard let window = self.window else { return }

        DispatchQueue.main.async {
            window.alphaValue = 1.0
            window.makeKeyAndOrderFront(nil)
        }
    }

    func handleSelectionChange(for element: AXUIElement) {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))

        // Check if the element is valid
        var elementPid: pid_t = 0
        let pidResult = AXUIElementGetPid(element, &elementPid)
        if pidResult != .success {
            print("Invalid element (cannot get pid). Skipping.")
            return
        }
        if elementPid == getpid() {
            print("Ignoring selection change from our own process.")
            return
        }

        guard mode == .highlightTopEdgeMode else { return }
        handleHighlightTopEdgeMode(element, shouldAnimate: true)

        // Store the selected text when the selection changes
        selectedText = getSelectedText(from: element)
    }

    private func adjustWindowPosition(with rect: CGRect) {
        DispatchQueue.main.async {
            var adjustedRect = rect

            // Get the primary screen
            guard let primaryScreen = NSScreen.screens.first else {
                print("No primary screen found.")
                return
            }

            guard let currentScreen = NSScreen.main else {
                print("No main screen found.")
                return
            }

            // Flip the y-coordinate from Quartz to Cocoa coordinate system
            adjustedRect.origin.y = primaryScreen.frame.maxY - (adjustedRect.origin.y + adjustedRect.size.height)

            // Now, adjustedRect.origin is in Cocoa coordinate system

            // Get the window's height
            let windowHeight = self.window?.frame.height ?? 0

            // Calculate the window's y-position to place it above the selection
            var windowOriginY = adjustedRect.origin.y + adjustedRect.size.height

            // Ensure the window doesn't go off-screen vertically
            let visibleFrame = currentScreen.visibleFrame

            // If the window would go off the top of the screen, position it below the selection
            if windowOriginY + windowHeight > visibleFrame.maxY {
                // Position the window below the selection
                windowOriginY = adjustedRect.origin.y - windowHeight
                print("Adjusting window position to below the selection.")
            }

            // Set the window's position
            self.window?.setFrameOrigin(NSPoint(x: adjustedRect.origin.x, y: windowOriginY))
            print("Window positioned at: \(NSPoint(x: adjustedRect.origin.x, y: windowOriginY))")
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

    func findElementWithAttribute(element: AXUIElement, attribute: CFString, maxDepth: Int = 5) -> AXUIElement? {
        func helper(currentElement: AXUIElement, currentDepth: Int) -> AXUIElement? {
            if currentDepth > maxDepth {
                return nil
            }

            // Check if the element is valid
            var elementPid: pid_t = 0
            let pidResult = AXUIElementGetPid(currentElement, &elementPid)
            if pidResult != .success {
                print("Invalid element (cannot get pid). Skipping.")
                return nil
            }

            // Attempt to get the attribute names
            var attributeNamesCFArray: CFArray?
            let namesResult = AXUIElementCopyAttributeNames(currentElement, &attributeNamesCFArray)
            if namesResult == .success, let namesArray = attributeNamesCFArray as? [String] {
                if namesArray.contains(attribute as String) {
                    return currentElement
                }

                // Get children
                var childrenValue: CFTypeRef?
                let childrenResult = AXUIElementCopyAttributeValue(currentElement, kAXChildrenAttribute as CFString, &childrenValue)
                if childrenResult == .success, let childrenArray = childrenValue as? [AXUIElement] {
                    for child in childrenArray {
                        if let foundElement = helper(currentElement: child, currentDepth: currentDepth + 1) {
                            return foundElement
                        }
                    }
                } else {
                    print("Failed to get children or no children. Error: \(childrenResult.rawValue)")
                }
            } else {
                print("Failed to get attribute names for element. Skipping. Error: \(namesResult.rawValue)")
            }
            return nil
        }

        return helper(currentElement: element, currentDepth: 0)
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

    static func insertText(_ text: String) {
        shared.insertText(text)
    }

    func insertText(_ textToInsert: String) {
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
                        let newText = nsCurrentValue.replacingCharacters(in: NSRange(location: range.location, length: range.length), with: textToInsert)

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
#endif
