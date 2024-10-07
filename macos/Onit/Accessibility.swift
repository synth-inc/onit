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
        let notificationCenter = NSWorkspace.shared.notificationCenter

        // Observe when any application is activated
        nsObjectObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let self = self else { return }
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                // Skip if the activated app is our own app
                if app.processIdentifier == getpid() {
                    print("Ignoring activation of our own app.")
                    return
                }
                print("\nApplication activated: \(app.localizedName ?? "Unknown")")
                currentSource = app.localizedName
                self.setupObserver(for: app.processIdentifier)
            }

            // Handle app activation
            self.handleAppActivation()
        }

        // Observe when any application is deactivated
        notificationCenter.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let self = self else { return }
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                print("\nApplication deactivated: \(app.localizedName ?? "Unknown")")
            }

            // Handle app deactivation
            self.handleAppDeactivation()
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
        case kAXFocusedUIElementChangedNotification as String:
            handleFocusChange(for: element)
        case kAXSelectedTextChangedNotification as String:
            handleSelectionChange(for: element)
        case kAXBoundsChangedNotification as String:
            handleBoundsChanged(for: element)
        case kAXValueChangedNotification as String:
            handleValueChanged(for: element)
        default:
            break
        }
    }

    func handleValueChanged(for element: AXUIElement) {
        print("Handling value changed...")

        // Re-fetch the bounding rectangle for the selected text
        if let observedElement = observedElementForSelection?.takeUnretainedValue() {
            handleHighlightTopEdgeMode(observedElement, shouldAnimate: false)
        }
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
            let accessibilityInstance = Unmanaged<Accessibility>.fromOpaque(refcon!).takeUnretainedValue()
            // Check if the notification comes from our own process
            var elementPid: pid_t = 0
            let pidResult = AXUIElementGetPid(element, &elementPid)
            if pidResult == .success {
                if elementPid == getpid() {
                    print("Ignoring system-wide notification from our own process.")
                    return
                }
            }
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
        // Skip if the PID is our own process
        if pid == getpid() {
            print("Not setting up observer for our own process.")
            return
        }
        print("Setting up observer for PID: \(pid)")
        let appElement = AXUIElementCreateApplication(pid)

        var observer: AXObserver?

        let observerCallback: AXObserverCallback = { _, element, notification, refcon in
            let accessibilityInstance = Unmanaged<Accessibility>.fromOpaque(refcon!).takeUnretainedValue()
            // Check if the notification comes from our own process
            var elementPid: pid_t = 0
            let pidResult = AXUIElementGetPid(element, &elementPid)
            if pidResult == .success {
                if elementPid == getpid() {
                    print("Ignoring notification from our own process.")
                    return
                }
            }
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
                handleFocusChange(for: axElement, shouldAnimate: false)
            } else {
                print("Focused element is not an AXUIElement.")
            }
        } else {
            print("Failed to get focused UI element within application. Error: \(result.rawValue)")
        }
    }

    func handleFocusChange(for focusedElement: AXUIElement, shouldAnimate: Bool = true) {
        // Check if the focused element comes from our own process
        var elementPid: pid_t = 0
        let pidResult = AXUIElementGetPid(focusedElement, &elementPid)
        if pidResult == .success {
            if elementPid == getpid() {
                print("Ignoring focus change from our own process.")
                return
            }
        } else {
            print("Failed to get pid of focused element. Error: \(pidResult.rawValue)")
        }

        switch mode {
        case .textfieldMode:
            handleTextFieldMode(for: focusedElement)
        case .highlightTopEdgeMode:
            // Remove previous selection observer
            if let previousElement = observedElementForSelection, let observer = observer {
                AXObserverRemoveNotification(observer, previousElement.takeUnretainedValue(), kAXSelectedTextChangedNotification as CFString)
                AXObserverRemoveNotification(observer, previousElement.takeUnretainedValue(), kAXBoundsChangedNotification as CFString)
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
            let result1 = AXObserverAddNotification(observer, elementToObserve, kAXSelectedTextChangedNotification as CFString, Unmanaged.passUnretained(self).toOpaque())
            let result2 = AXObserverAddNotification(observer, elementToObserve, kAXBoundsChangedNotification as CFString, Unmanaged.passUnretained(self).toOpaque())

            if result1 == .success && result2 == .success {
                print("Added selection and bounds changed observers to element.")
            } else {
                print("Failed to add observers. Errors: \(result1.rawValue), \(result2.rawValue)")
                observedElementForSelection?.release()
                observedElementForSelection = nil
            }

            // Store the selected text
            selectedText = getSelectedText(from: elementToObserve)

            // Handle initial selection
            handleHighlightTopEdgeMode(elementToObserve, shouldAnimate: shouldAnimate)
        }
    }

    func findAncestor(element: AXUIElement, role: String) -> AXUIElement? {
        var currentElement: AXUIElement? = element
        while let element = currentElement {
            var roleValue: CFTypeRef?
            let roleResult = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
            if roleResult == .success, let roleStr = roleValue as? String, roleStr == role {
                return element
            }
            // Get the parent
            var parentValue: CFTypeRef?
            let parentResult = AXUIElementCopyAttributeValue(element, kAXParentAttribute as CFString, &parentValue)
            if parentResult == .success {
                let parentElement = parentValue as! AXUIElement
                currentElement = parentElement
            } else {
                break
            }
        }
        return nil
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

    private func handleHighlightTopEdgeMode(_ focusedElement: AXUIElement, shouldAnimate: Bool = true) {
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
                                if shouldAnimate {
                                    self.showWindowWithAnimation()
                                    print("Window shown at selected text position with animation.")
                                } else {
                                    self.showWindowWithoutAnimation()
                                    print("Window shown at selected text position without animation.")
                                }
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

    func getSelectedText(from focusedElement: AXUIElement) -> String? {
        // 1. Get the selected text range attribute
        var selectedRangeValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, &selectedRangeValue)

        guard result == .success else {
            print("Failed to get the selected text range.")
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
        // Check if the element comes from our own process
        var elementPid: pid_t = 0
        let pidResult = AXUIElementGetPid(element, &elementPid)
        if pidResult == .success {
            if elementPid == getpid() {
                print("Ignoring selection change from our own process.")
                return
            }
        } else {
            print("Failed to get pid of element. Error: \(pidResult.rawValue)")
        }

        guard mode == .highlightTopEdgeMode else { return }
        handleHighlightTopEdgeMode(element, shouldAnimate: true)

        // Store the selected text when the selection changes
        selectedText = getSelectedText(from: element)
    }

    private func adjustWindowPosition(with rect: CGRect) {
        DispatchQueue.main.async {
            var adjustedRect = rect

            // Get the primary screen (main display)
            guard let primaryScreen = NSScreen.screens.first else {
                print("No screens available.")
                return
            }

            let primaryScreenFrame = primaryScreen.frame
            let visibleFrame = primaryScreen.visibleFrame

            // Adjust the y-coordinate from top-left to bottom-left origin using the primary screen
            adjustedRect.origin.y = primaryScreenFrame.maxY - (adjustedRect.origin.y + adjustedRect.height)

            let windowHeight = self.window?.frame.height ?? 0

            // Calculate positions to place the window above or below the selection
            let positionAbove = adjustedRect.origin.y + adjustedRect.height // Window's bottom edge aligns with selection's top edge
            let positionBelow = adjustedRect.origin.y - windowHeight // Window's top edge aligns with selection's bottom edge

            // Determine if positioning above would cause the window to go off the top of the visible area (menu bar)
            let windowTopEdgeIfAbove = positionAbove + windowHeight

            let windowOriginY: CGFloat

            if windowTopEdgeIfAbove > visibleFrame.maxY {
                // Position the window below the selection, ensuring it doesn't go off-screen
                windowOriginY = max(positionBelow, visibleFrame.minY)
                print("Window positioned below the selection at: \(NSPoint(x: adjustedRect.origin.x, y: windowOriginY))")
            } else {
                // Position the window above the selection
                windowOriginY = max(positionAbove, visibleFrame.minY)
                print("Window positioned above the selection at: \(NSPoint(x: adjustedRect.origin.x, y: windowOriginY))")
            }

            self.window?.setFrameOrigin(NSPoint(x: adjustedRect.origin.x, y: windowOriginY))
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
#endif
