//  AppDelegate+Accessibility.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

@preconcurrency import ApplicationServices
import SwiftUI
import Combine

enum AccessibilityMode {
    case textfieldMode
    case highlightTopEdgeMode
}

#if !targetEnvironment(simulator)
@MainActor
class Accessibility {
    @Environment(\.model) var model
    
    var selectedText: [pid_t: String] = [:]
    var currentApplication: pid_t = 0
    var currentSource: String?
    var selectedSource: String?
    var focusedElement: AXUIElement?
    var appElement: AXUIElement?

    static var input: Input? {
        guard let text = shared.selectedText[shared.currentApplication] else { return nil }
        return .init(selectedText: text, application: shared.selectedSource)
    }

    private var mode: AccessibilityMode = .highlightTopEdgeMode

    let kAXFrameAttribute = "AXFrame"
    let kAXBoundsChangedNotification = "AXBoundsChanged"

    private var window: NSWindow?

    private var nsObjectObserver: NSObjectProtocol?
    private var observers: [pid_t: AXObserver] = [:]
    private var runLoopSource: CFRunLoopSource?
    private var tapObserver: CFMachPort?


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

    static func observeSystemClicks() {
        DispatchQueue.main.async {
            shared.observeSystemClicks()
        }
    }
    
    private func observeSystemClicks() {
        // Setup mouse click observer
        let eventMask = (1 << CGEventType.leftMouseUp.rawValue) |
                        (1 << CGEventType.rightMouseUp.rawValue)

        if let eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                DispatchQueue.main.async {
                    switch type {
                    case .leftMouseDown, .rightMouseDown:
                        print("Mouse down detected!")
                    case .leftMouseUp, .rightMouseUp:
                        print("Mouse up detected!")
                        Task { @MainActor in
                            Accessibility.shared.handleMouseUp()
                        }
                    default:
                        break
                    }
                }
                return Unmanaged.passUnretained(event) // Ensure the event is returned
            },
            userInfo: nil
        ) {
            self.tapObserver = eventTap
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            print("Failed to create event tap.")
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
            Task { @MainActor in
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
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                print("\nApplication deactivated: \(app.localizedName ?? "Unknown")")
            }

            Task { @MainActor in
                guard let self = self else { return }

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
            print("Ignoring ")
//            let appElement = AXUIElementCreateApplication(pid)
//            handleInitialFocus(for: appElement)
        } else {
            print("Ignoring handleAppActivation for our own app.")
        }
    }

    func handleAccessibilityNotification(_ notification: String, element: AXUIElement) {
        dispatchPrecondition(condition: .onQueue(.main))

        // Check if the notification comes from our own process
        var elementPid: pid_t = 0
        let pidResult = AXUIElementGetPid(element, &elementPid)
        if pidResult == .success {
            if elementPid == getpid() {
                print("Ignoring notification from our own process. \(elementPid)")
                return
            }
        } else {
            print("Failed to get pid of element. Error: \(pidResult.rawValue)")
        }

        switch notification {
        case kAXLayoutChangedNotification:
            print("Layout Changed Notification!")
        case kAXFocusedUIElementChangedNotification:
            print("Focus Changed Notification!!")
//            handleFocusChange(for: element)
        case kAXSelectedTextChangedNotification:
            print("Selected Text Changed Notification!")
            handleSelectionChange(for: element)
        case kAXBoundsChangedNotification:
            print("Bounds changed Notification!")
//            handleBoundsChanged(for: element)
        case kAXValueChangedNotification:
            // There are ton of these
            break
        case kAXAnnouncementRequestedNotification:
            print("Announcement Requested Notification!")
        case kAXApplicationActivatedNotification:
            print("Application Activated Notification! \(elementPid)" )
        case kAXApplicationDeactivatedNotification:
            print("Application Deactivated Notification! \(elementPid)")
        case kAXApplicationHiddenNotification:
            print("Application Hidden Notification!")
        case kAXApplicationShownNotification:
            print("Application Shown Notification!")
        case kAXCreatedNotification:
            print("Created Notification!")
        case kAXDrawerCreatedNotification:
            print("Drawer Created Notification!")
        case kAXFocusedWindowChangedNotification:
            print("Focused Window Changed Notification!")
        case kAXHelpTagCreatedNotification:
            print("Help Tag Created Notification!")
        case kAXMainWindowChangedNotification:
            print("Main Window Changed Notification!")
        case kAXMenuClosedNotification:
            print("Menu Closed Notification!")
        case kAXMenuItemSelectedNotification:
            print("Menu Item Selected Notification!")
        case kAXMenuOpenedNotification:
            print("Menu Opened Notification!")
        case kAXMovedNotification:
            print("Moved Notification!")
        case kAXResizedNotification:
            print("Resized Notification!")
        case kAXRowCollapsedNotification:
            print("Row Collapsed Notification!")
        case kAXRowCountChangedNotification:
            print("Row Count Changed Notification!")
        case kAXRowExpandedNotification:
            print("Row Expanded Notification!")
        case kAXSelectedCellsChangedNotification:
            print("Selected Cells Changed Notification!")
        case kAXSelectedChildrenChangedNotification:
            print("Selected Children Changed Notification!")
        case kAXSelectedChildrenMovedNotification:
            print("Selected Children Moved Notification!")
        case kAXSelectedColumnsChangedNotification:
            print("Selected Columns Changed Notification!")
        case kAXSelectedRowsChangedNotification:
            print("Selected Rows Changed Notification!")
        case kAXSheetCreatedNotification:
            print("Sheet Created Notification!")
        case kAXTitleChangedNotification:
            print("Title Changed Notification!")
        case kAXUIElementDestroyedNotification:
//            print("UI Element Destroyed Notification!")
            break
        case kAXUnitsChangedNotification:
            print("Units Changed Notification!")
        case kAXWindowCreatedNotification:
            print("Window Created Notification!")
        case kAXWindowDeminiaturizedNotification:
            print("Window Deminiaturized Notification!")
        case kAXWindowMiniaturizedNotification:
            print("Window Miniaturized Notification!")
        case kAXWindowMovedNotification:
            print("Window Moved Notification!")
        case kAXWindowResizedNotification:
            print("Window Resized Notification!")
        default:
            break
        }
    }

    func handleValueChanged(for element: AXUIElement) {
        print("Handling value changed...")
    }

    func handleBoundsChanged(for element: AXUIElement) {
        print("Handling bounds changed...")
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
        
        self.currentApplication = pid
        // Check if the process ID is already in self.observers
        guard self.observers[pid] == nil else {
            print("Observer for PID: \(pid) already exists. Skipping setup.")
            return
        }

        print("Setting up observer for PID: \(pid)")
        self.appElement = AXUIElementCreateApplication(pid)

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
            // Release the previous observer if it exists
            self.observers[pid] = observer
            let refCon = Unmanaged.passUnretained(self).toOpaque()
            if let appElement = self.appElement {
                let notifications = [
                    kAXAnnouncementRequestedNotification,
                    kAXApplicationActivatedNotification,
                    kAXApplicationDeactivatedNotification,
                    kAXApplicationHiddenNotification,
                    kAXApplicationShownNotification,
                    kAXCreatedNotification,
                    kAXDrawerCreatedNotification,
                    kAXFocusedUIElementChangedNotification,
                    kAXFocusedWindowChangedNotification,
                    kAXHelpTagCreatedNotification,
                    kAXLayoutChangedNotification,
                    kAXMainWindowChangedNotification,
                    kAXMenuClosedNotification,
                    kAXMenuItemSelectedNotification,
                    kAXMenuOpenedNotification,
                    kAXMovedNotification,
                    kAXResizedNotification,
                    kAXRowCollapsedNotification,
                    kAXRowCountChangedNotification,
                    kAXRowExpandedNotification,
                    kAXSelectedCellsChangedNotification,
                    kAXSelectedChildrenChangedNotification,
                    kAXSelectedChildrenMovedNotification,
                    kAXSelectedColumnsChangedNotification,
                    kAXSelectedRowsChangedNotification,
                    kAXSelectedTextChangedNotification,
                    kAXSheetCreatedNotification,
                    kAXTitleChangedNotification,
                    kAXUIElementDestroyedNotification,
                    kAXUnitsChangedNotification,
                    kAXValueChangedNotification,
                    kAXWindowCreatedNotification,
                    kAXWindowDeminiaturizedNotification,
                    kAXWindowMiniaturizedNotification,
                    kAXWindowMovedNotification,
                    kAXWindowResizedNotification
                ]

                for notification in notifications {
                    AXObserverAddNotification(observer, appElement, notification as CFString, refCon)
                }
                // Add the observer to the main run loop
                CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
                print("Observer registered for PID: \(pid)")
            }
        } else {
            print("Failed to create observer for PID: \(pid) with result: \(result)")
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

        // Store the selected text when the selection changes
        let newSelectedText = getSelectedText(from: element)
        if let newSelectedText = newSelectedText {
            if newSelectedText.count > 1 {
                if self.window?.isVisible == false {
                    self.adjustWindowToTopRight()
                    self.showWindowWithAnimation()
                }
            } else{
                print("New selected text count is not greater than 1.")
            }
        } else {
            print("No new selected text.")
        }
        self.selectedText[self.currentApplication] = newSelectedText

        // If nothing is selected, hide the window. 
        if self.selectedText[self.currentApplication] == nil {
            self.window?.orderOut(nil)
        }

        model.selectedText = self.selectedText[self.currentApplication] ?? ""
        model.sourceText = self.currentSource ?? ""
        print("Selected text: \(selectedText)")
        print("from PID: \(elementPid)")
    }
    
    private func adjustWindowToTopRight() {
        DispatchQueue.main.async {
            guard let currentScreen = NSScreen.main else {
                print("No main screen found.")
                return
            }

            // Get the window's height
            let windowHeight = self.window?.frame.height ?? 0
            let windowWidth = self.window?.frame.width ?? 0

            // Calculate the new origin for the window to be at the top right corner of the current screen
            let newOriginX = currentScreen.visibleFrame.maxX - (windowWidth - 10)
            let newOriginY = currentScreen.visibleFrame.maxY - (windowHeight + 85)
            
            // Set the window's position to the calculated top right corner
            self.window?.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
            print("Window moved to top right corner at: \(NSPoint(x: newOriginX, y: newOriginY))")
        }
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

    
    
    func findElementsWithAttribute(element: AXUIElement, attribute: CFString) -> [AXUIElement] {
        var elementsWithAttribute: [AXUIElement] = []

        func helper(currentElement: AXUIElement) {
            // Check if the element is valid
            var elementPid: pid_t = 0
            let pidResult = AXUIElementGetPid(currentElement, &elementPid)
            if pidResult != .success {
                print("Invalid element (cannot get pid). Skipping.")
                return
            }

            // Attempt to get the attribute names
            var attributeNamesCFArray: CFArray?
            let namesResult = AXUIElementCopyAttributeNames(currentElement, &attributeNamesCFArray)
            if namesResult == .success, let namesArray = attributeNamesCFArray as? [String] {
                if namesArray.contains(attribute as String) {
                    elementsWithAttribute.append(currentElement)
                }

                // Get children
                var childrenValue: CFTypeRef?
                let childrenResult = AXUIElementCopyAttributeValue(currentElement, kAXChildrenAttribute as CFString, &childrenValue)
                if childrenResult == .success, let childrenArray = childrenValue as? [AXUIElement] {
                    for child in childrenArray {
                        helper(currentElement: child)
                    }
                }
//                else {
//                    print("Failed to get children or no children. Error: \(childrenResult.rawValue)")
//                }
            } else {
                print("Failed to get attribute names for element. Skipping. Error: \(namesResult.rawValue)")
            }
        }

        helper(currentElement: element)
        return elementsWithAttribute
    }

    func showWindowWithAnimation() {
        guard let window = self.window else { return }

        DispatchQueue.main.async {
            // Ensure the contentView is layer-backed
            window.contentView?.wantsLayer = true

            // Get the contentView's layer
            guard let layer = window.contentView?.layer else { return }

            // Set the anchorPoint to the right and adjust the layer's position
            let oldFrame = layer.frame
            layer.anchorPoint = CGPoint(x: 1.0, y: 0.5)
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
    
    static func focusOnit() {
        // Create an AXUIElement for the application
        let appElement = AXUIElementCreateApplication(shared.currentApplication)

        // Get the main window of the application
        var mainWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXMainWindowAttribute as CFString, &mainWindow)

        if result == .success, let windowElement = mainWindow {
            // Set the window as the focused element
            AXUIElementSetAttributeValue(windowElement as! AXUIElement, kAXFocusedAttribute as CFString, kCFBooleanTrue)     
            // Activate the application using NSRunningApplication
            if let runningApp = NSRunningApplication(processIdentifier: shared.currentApplication) {
                runningApp.activate(options: [.activateAllWindows])
            }
        }
        // Not sure why but this needs to be called again to work
        NSRunningApplication.current.activate(options: [.activateAllWindows])
    }

    func handleMouseUp() {
        if let appElement = self.appElement {
            print("Mouse up!")
        }
        else {
            print("No app ELement, skipping")
        }
    }
    
    deinit {
        for (_, observer) in self.observers {
            let runLoopSource = AXObserverGetRunLoopSource(observer)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
    }
}

#endif
