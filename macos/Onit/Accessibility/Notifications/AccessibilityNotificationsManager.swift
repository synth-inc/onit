//
//  AccessibilityNotificationsManager.swift
//  Onit
//
//  Created by Kévin Naudin on 22/01/2025.
//

import ApplicationServices
import Foundation
import SwiftUI

@MainActor
class AccessibilityNotificationsManager: ObservableObject {
    
    // MARK: - Singleton instance
    
    static let shared = AccessibilityNotificationsManager()
    
    // MARK: - ScreenResult
    
    @Published private(set) var screenResult: ScreenResult = .init()
    
    struct ScreenResult {
        struct UserInteractions {
            var selectedText: String?
            var input: String?
        }
        
        var elapsedTime: String?
        var applicationName: String?
        var applicationTitle: String?
        var userInteraction: UserInteractions = .init()
        var others: [String: String]?
    }
    
    // MARK: - Properties
    
    private var model: OnitModel?
    
    private var currentApplication: pid_t = 0
    
    private var currentSource: String?
    
    private var appElement: AXUIElement?
    
    private var observers: [pid_t: AXObserver] = [:]
    
    private var selectedSource: String?
    
    private var selectedTextByApp: [String: String] = [:]
    private var selectedElementByApp: [String: AXUIElement] = [:]
    
    private var valueDebounceWorkItem: DispatchWorkItem?
    
    private var selectionDebounceWorkItem: DispatchWorkItem?
    
    // MARK: - Initializers
    
    private init() { }
    
    // MARK: - Functions
    
    func setModel(_ model: OnitModel) {
        self.model = model
    }
    
    // MARK: Start / Stop
    
    func start() {
        startAppActivationObservers()
    }
    
    func stop() {
        for pid in observers.keys {
            stopAccessibilityObservers(for: pid)
        }
        
        stopAppActivationObservers()
        
        currentApplication = 0
        currentSource = nil
        appElement = nil
        observers.removeAll()
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
    
        print("Start accessibility observers for PID: \(pid)")
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
                for notification in Config.notifications {
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
        guard let appElement = self.appElement,
              let existingObserver = self.observers[pid] else { return }
        
        let runLoopSource = AXObserverGetRunLoopSource(existingObserver)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        
        for notification in Config.notifications {
            AXObserverRemoveNotification(existingObserver, appElement, notification as CFString)
        }
    
        self.observers.removeValue(forKey: pid)
        print("Stop accessibility observers for PID: \(pid).")
    }
    
    // MARK: Notifications handling
    
    @objc private func appActivationReceived(notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            Task { @MainActor in
                // TODO: KNA - Investigate on this
                // Skip if the activated app is our own app
                // There's an edge case where the panel somehow has a different processId.
                let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                if app.processIdentifier == getpid() || app.localizedName == appName {
                    print("Ignoring activation of our own app.")
                    return
                }
                
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
            print("\nApplication deactivated: \(app.localizedName ?? "Unknown") \(app.processIdentifier)")
            
            self.stopAccessibilityObservers(for: app.processIdentifier)
        }
    }
    
    // MARK: Handling app activated/deactived

    private func handleAppActivation(appName: String?, processID: pid_t) {
        guard processID != getpid() else {
            print("Ignoring handleAppActivation for our own app.")
            return
        }
        
        let selectedText = selectedTextByApp[appName ?? "Unknown"]
        let selectedElement = selectedElementByApp[appName ?? "Unknown"]
        
        print("\nApplication activated: \(appName ?? "Unknown") \(processID) selected text: \"\(selectedText ?? "")\"")
        
        let newAppElement = processID.getAXUIElement()
        self.appElement = newAppElement
        self.currentApplication = processID
        self.currentSource = appName
        
        processSelectedText(selectedText, for: selectedElement)

        parseAccessibility(for: newAppElement)
            
        // print("Text in application: \(textInApplication)")
        // let appElement = pid.getAXUIElement()
        // handleInitialFocus(for: appElement)
    }
    
    private func handleAccessibilityNotifications(_ notification: String, info: [String: Any], element: AXUIElement, observer: AXObserver) {
        dispatchPrecondition(condition: .onQueue(.main))

        handleExternalElement(element) { [weak self] elementPid in
            switch notification {
            case kAXLayoutChangedNotification:
                print("Layout Changed Notification!")
            case kAXFocusedUIElementChangedNotification:
    //            print("Focus Changed Notification!!")
                self?.handleFocusChange(for: element)
            case kAXSelectedTextChangedNotification:
                self?.handleSelectionChange(for: element)
            case "AXBoundsChanged":
                print("Bounds changed Notification!")
    //            handleBoundsChanged(for: element)
            case kAXValueChangedNotification:
                self?.handleValueChanged(for: element)
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
                self?.handleFocusChange(for: element)
            case kAXSelectedRowsChangedNotification:
                print("Selected Rows Changed Notification!")
                self?.handleFocusChange(for: element)
            case kAXSheetCreatedNotification:
                print("Sheet Created Notification!")
            case kAXTitleChangedNotification:
                self?.handleTitleChange(for: element)
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
    }
    
    func handleFocusChange(for element: AXUIElement) {
        handleExternalElement(element) { [weak self] elementPid in
            print("Focus change from pid: \(elementPid)")
            
            if let appElement = self?.appElement {
                self?.parseAccessibility(for: appElement)
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
        // Filter on text area or textfield
        guard let role = element.role(), [kAXTextFieldRole, kAXTextAreaRole].contains(role) else { return }
        
        valueDebounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.processValueChanged(for: element)
        }
        
        valueDebounceWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Config.debounceInterval, execute: workItem)
    }
    
    private func handleSelectionChange(for element: AXUIElement) {
        guard AccessibilityTextSelectionFilter.filter(element: element) == false else { return }
        
        selectionDebounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.processSelectionChange(for: element)
        }
        
        selectionDebounceWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Config.debounceInterval, execute: workItem)
    }
    
    // MARK: Parsing
    
    private func parseAccessibility(for element: AXUIElement) {
        Task {
            var results = await AccessibilityParser.shared.getAllTextInElement(appElement: element)
            
            screenResult.elapsedTime = results?[AccessibilityParsedElements.elapsedTime]
            screenResult.applicationName = results?[AccessibilityParsedElements.applicationName]
            screenResult.applicationTitle = results?[AccessibilityParsedElements.applicationTitle]
            
            results?.removeValue(forKey: AccessibilityParsedElements.elapsedTime)
            results?.removeValue(forKey: AccessibilityParsedElements.applicationName)
            results?.removeValue(forKey: AccessibilityParsedElements.applicationTitle)
            
            screenResult.others = results
            
            showDebug()
        }
    }
    
    // MARK: Value Changed
    
    private func processValueChanged(for element: AXUIElement) {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))
        
        handleExternalElement(element) { [weak self] _ in
            guard let value = element.value() else {
                self?.screenResult.userInteraction.input = nil
                self?.showDebug()
                return
            }
            
            self?.screenResult.userInteraction.input = value
            
            self?.showDebug()
        }
    }
    
    // MARK: Text Selection
    
    private func processSelectionChange(for element: AXUIElement) {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))
        
        handleExternalElement(element) { [weak self] pid in
            let selectedTextExtracted = self?.extractSelectedText(from: element)
            
            self?.processSelectedText(selectedTextExtracted, for: element)
            self?.selectedTextByApp[pid.getAppName() ?? "Unknown"] = selectedTextExtracted
            self?.selectedElementByApp[pid.getAppName() ?? "Unknown"] = element
            self?.showDebug()
        }
    }
    
    private func processSelectedText(_ text: String?, for element: AXUIElement?) {
        guard let selectedText = text,
              let selectedElement = element,
              !selectedText.isEmpty else {
            
            selectedSource = nil
            model?.pendingInput = nil
            HighlightHintWindowController.shared.hide()
            
            return
        }
        screenResult.userInteraction.selectedText = selectedText
        
        selectedSource = currentSource

        let bound = selectedElement.selectedTextBound()
        HighlightHintWindowController.shared.show(bound)

        model?.pendingInput = Input(selectedText: selectedText, application: currentSource ?? "")
    }
    
    private func extractSelectedText(from element: AXUIElement) -> String? {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))
        
        var selectedRangeValue: CFTypeRef?
        var selectedRange = CFRange()
        
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedRangeValue) == .success else {
            print("Failed to get selected text range")
            return nil
        }
        let rangeValue = selectedRangeValue as! AXValue
        
        guard AXValueGetValue(rangeValue, .cfRange, &selectedRange) else {
            print("Failed to convert range value")
            return nil
        }
        
        var selectedTextValue: CFTypeRef?
        let textResult = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &selectedTextValue
        )
        
        guard textResult == .success,
              let selectedText = selectedTextValue as? String,
              !selectedText.isEmpty else {
            return nil
        }
        
        return selectedText
    }
    
    /** Ensure the received `AXUIElement` is not from our process */
    private func handleExternalElement(_ element: AXUIElement, callback: @escaping (pid_t) -> Void) {
        var elementPid: pid_t = 0
        
        guard AXUIElementGetPid(element, &elementPid) == .success, elementPid != getpid() else {
            return
        }
        
        callback(elementPid)
    }
    
    // MARK: Debug
    
    private func showDebug() {
        var debugText = """
        ===== Debug Information =====
        
        Elapsed Time: \(screenResult.elapsedTime ?? "N/A")
        
        Application Name: \(screenResult.applicationName ?? "N/A")
        
        Application Title: \(screenResult.applicationTitle ?? "N/A")
        
        Selected Text: \(screenResult.userInteraction.selectedText ?? "N/A")
        
        User Input: \(screenResult.userInteraction.input ?? "N/A")
        
        =============================
        
        """

        if let results = screenResult.others {
            debugText += "\n======== Additional Data ========\n"
            for result in results.sorted(by: { $0.key < $1.key }) {
                debugText += """
                
                ---------------------------------
                Key: \(result.key)
                ---------------------------------
                \(result.value)
                """
            }
            debugText += "\n=================================\n"
        } else {
            debugText += "\nNo additional data available.\n"
        }

        if let model = self.model {
            model.debugText = debugText
        }
    }
}
