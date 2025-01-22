//
//  AccessibilityNotificationsManager.swift
//  Onit
//
//  Created by Kévin Naudin on 22/01/2025.
//

import Foundation
import SwiftUI

@MainActor
class AccessibilityNotificationsManager {
    
    // MARK: - Singleton instance
    
    static let shared = AccessibilityNotificationsManager()
    
    // MARK: - Properties
    
    private var notifications = [
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
//        TODO: KNA - kAXSelectedTextChangedNotification,
        kAXSheetCreatedNotification,
        kAXTitleChangedNotification,
        kAXUIElementDestroyedNotification,
        kAXUnitsChangedNotification,
//            kAXValueChangedNotification,
        kAXWindowCreatedNotification,
        kAXWindowDeminiaturizedNotification,
        kAXWindowMiniaturizedNotification,
        kAXWindowMovedNotification,
        kAXWindowResizedNotification
    ]
    
    private var window: NSWindow? {
        didSet {
            print("resetting Accessibility Window!")
        }
    }
    
    private var model: OnitModel?
    
    private var currentApplication: pid_t = 0
    
    private var currentSource: String?
    
    private var appElement: AXUIElement?
    
    private var observers: [pid_t: AXObserver] = [:]
    
    private var selectedSource: String?
    
    private var selectedText: [pid_t: String] = [:]
    
    // MARK: - Initializers
    
    private init() { }
    
    // MARK: - Functions
    
    func start() {
        startAppActivationObservers()
    }
    
    func stop() {
        // TODO: KNA - Find a way to remove AXObserver
        // Actually when we grant/deny in loop permission, the observers stack
        for pid in observers.keys {
            stopAccessibilityObservers(for: pid)
        }
        
        stopAppActivationObservers()
        
        currentApplication = 0
        currentSource = nil
        appElement = nil
        observers = [:]
    }
    
    func setupWindow(_ window: NSWindow) {
        self.window = window
    }
    
    func setModel(_ model: OnitModel) {
        self.model = model
    }
    
    private func startAppActivationObservers() {
        // Observe when any application is activated
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(appActivationReceived),
                                                          name: NSWorkspace.didActivateApplicationNotification,
                                                          object: nil)
        
        

        // Observe when any application is deactivated
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(appDeactivationReceived),
                                                          name: NSWorkspace.didDeactivateApplicationNotification,
                                                          object: nil)
    }
    
    private func stopAppActivationObservers() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    private func startAccessibilityObservers(for pid: pid_t) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.startAccessibilityObservers(for: pid)
            }
            return
        }
        // Skip if the PID is our own process
        if pid == getpid() {
            print("Not setting up observer for our own process.")
            return
        }
    
        print("Setting up observer for PID: \(pid)")
        if let appElement = self.appElement {
            var observer: AXObserver?
            
            let observerCallback: AXObserverCallbackWithInfo = { observer, element, notification, userInfo, refcon in
                // Dispatch to main thread immediately
                DispatchQueue.main.async {
                    let accessibilityInstance = Unmanaged<AccessibilityNotificationsManager>.fromOpaque(refcon!).takeUnretainedValue()
                    accessibilityInstance.handleAccessibilityNotifications(notification as String, info: userInfo as! Dictionary<String, Any> as Dictionary, element: element, observer: observer)
                }
            }
            
            let result = AXObserverCreateWithInfoCallback(pid, observerCallback, &observer)
            
            if result == .success, let observer = observer {
                // Release the previous observer if it exists
                self.observers[pid] = observer
                let refCon = Unmanaged.passUnretained(self).toOpaque()
                for notification in notifications {
                    // print("Registering observer for \(notification)...")
                    AXObserverAddNotification(observer, appElement, notification as CFString, refCon)
                }
                // Add the observer to the main run loop
                CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
                print("Observer registered for PID: \(pid)")
                
            } else {
                print("Failed to create observer for PID: \(pid) with result: \(result)")
            }
        }
    }
    
    private func stopAccessibilityObservers(for pid: pid_t) {
        // Check if the process ID is already in self.observers
        guard let appElement = self.appElement else { return }
        
        if let existingObserver = self.observers[pid] {
            for notification in self.notifications {
                AXObserverRemoveNotification(existingObserver, appElement, notification as CFString)
            }
            self.observers[pid] = nil
            print("Removed existing observer for PID: \(pid).")
        }
    }
    
    // MARK: - Notifications handling
    
    @objc private func appActivationReceived(notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            Task { @MainActor in
                // Skip if the activated app is our own app
                print("Onit process ID: \(getpid())")
                // There's an edge case where the panel somehow has a different processId.
                let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                print("App name: \(appName ?? "Unknown")")
                if app.processIdentifier == getpid() || app.localizedName == appName {
                    print("Ignoring activation of our own app.")
                    return
                }
                print("\nApplication activated: \(app.localizedName ?? "Unknown") \(app.processIdentifier)")
                
                // If it's the same as last time, we just toggled between Onit and that app, no need to remove observers and set up new ones.
                if app.processIdentifier != self.currentApplication {
                    self.stopAccessibilityObservers(for: app.processIdentifier)
                    self.handleAppActivation(appName: app.localizedName, processID: app.processIdentifier)
                    self.startAccessibilityObservers(for: app.processIdentifier)
                }
            }
        }
    }
    
    @objc private func appDeactivationReceived(notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            print("\nApplication deactivated: \(app.localizedName ?? "Unknown")")
        }

        Task { @MainActor in
            
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

    private func handleAppActivation(appName: String?, processID: pid_t) {
        // Check if there's an existing text selection
        if let focusedApp = NSWorkspace.shared.frontmostApplication, focusedApp.processIdentifier != getpid() {
            let pid = focusedApp.processIdentifier
            
            let newAppElement = AXUIElementCreateApplication(pid)
            self.appElement = newAppElement
            self.currentApplication = pid
            self.currentSource = focusedApp.localizedName

            Task {
                let textInApplication = await AccessibilityParser.shared.getAllTextInElement(appElement: newAppElement)
                
                if let model = self.model {
                    model.debugText = textInApplication
                }
            }
            // print("Text in application: \(textInApplication)")
            // let appElement = AXUIElementCreateApplication(pid)
            // handleInitialFocus(for: appElement)
        } else {
            print("Ignoring handleAppActivation for our own app.")
        }
    }
    
    private func handleAccessibilityNotifications(_ notification: String, info: [String: Any], element: AXUIElement, observer: AXObserver) {
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
//            print("Focus Changed Notification!!")
            handleFocusChange(for: element)
        case kAXSelectedTextChangedNotification:
            print("Selected Text Changed Notification!")
            handleSelectionChange(for: element)
        case "AXBoundsChanged":
            print("Bounds changed Notification!")
//            handleBoundsChanged(for: element)
        case kAXValueChangedNotification:
            handleValueChanged(for: element)
//            print("Value changed Notification!")
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
            // These handle tabbed interfaces
            handleFocusChange(for: element)
        case kAXSelectedRowsChangedNotification:
            print("Selected Rows Changed Notification!")
            handleFocusChange(for: element)
        case kAXSheetCreatedNotification:
            print("Sheet Created Notification!")
        case kAXTitleChangedNotification:
            handleTitleChange(for: element)
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
    
    func handleFocusChange(for element: AXUIElement) {
        // Check if the focused element is valid
        var elementPid: pid_t = 0
        let pidResult = AXUIElementGetPid(element, &elementPid)
        if pidResult != .success {
            print("Invalid focused element (cannot get pid). Skipping.")
            return
        }
        if elementPid == getpid() {
            print("Ignoring focus change from our own process.")
            return
        }
        print("Focus change from pid: \(elementPid)")
        // Read in context on FocusChange notifiications
        if let appElement = self.appElement {
            Task {
                let textInElement = await AccessibilityParser.shared.getAllTextInElement(appElement: appElement)
                
                if let model = self.model {
                    model.debugText = textInElement
                }
            }
        }
    }
    
    func handleTitleChange(for element: AXUIElement) {
        var titleValue: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
        if titleResult == .success, let title = titleValue as? String {
            print("Title Changed Notification! New title : \(title)")
        } else {
            print("Failed to get title for element. Error: \(titleResult.rawValue)")
        }
    }
    
    func handleValueChanged(for element: AXUIElement) {
        var valueValue: CFTypeRef?
        let valueResult = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueValue)
        if valueResult == .success, let value = valueValue as? String {
            print("Value Changed Notification! New value : \(value)")
        } else {
            print("Failed to get value for element. Error: \(valueResult.rawValue)")
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
                    WindowHelper.shared.adjustWindowToTopRight()
                    WindowHelper.shared.showWindowWithAnimation()
                }
                self.selectedText[self.currentApplication] = newSelectedText
                if let model = self.model {
                    let curSelectedText = self.selectedText[self.currentApplication] ?? ""
                    let curSourceText = self.currentSource ?? ""
                    
                    // Move these on to the model Input!
                    if curSelectedText != "" {
                        model.pendingInput = Input(selectedText: curSelectedText, application: curSourceText)
                    } else {
                        model.pendingInput = nil
                    }
                }
            } else{
                print("New selected text count is not greater than 1.")
                self.window?.orderOut(nil)
            }
        } else {
            print("No new selected text.")
            self.window?.orderOut(nil)
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

        // 3. Use AXStringForRangeParameterizedAttribute to get the text for the range
        var selectedTextValue: CFTypeRef?
        let textResult = AXUIElementCopyParameterizedAttributeValue(
            focusedElement,
            kAXStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &selectedTextValue
        )

        if textResult == .success, let selectedText = selectedTextValue as? String, !selectedText.isEmpty {
            // print("Selected text: \(selectedText)")
            self.selectedSource = currentSource
            return selectedText
        } else {
            print("Failed to get the selected text. Error: \(textResult.rawValue)")
            self.selectedSource = nil
            return nil
        }
    }
}
