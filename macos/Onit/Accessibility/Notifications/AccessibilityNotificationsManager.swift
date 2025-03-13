//
//  AccessibilityNotificationsManager.swift
//  Onit
//
//  Created by Kévin Naudin on 22/01/2025.
//

import ApplicationServices
import Foundation
import PostHog
import SwiftUI

@MainActor
class AccessibilityNotificationsManager: ObservableObject {

    // MARK: - Singleton instance

    static let shared = AccessibilityNotificationsManager()

    // MARK: - ScreenResult

    @Published private(set) var screenResult: ScreenResult = .init()
    @Published private(set) var activeWindowElement: AXUIElement?

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
        var errorMessage: String?  // Renamed field for error message
    }

    // MARK: - Properties

    private var model: OnitModel?

    private var currentSource: String?

    private var observers: [pid_t: AXObserver] = [:]

    private var selectedSource: String?

    private var selectedTextByApp: [String: String] = [:]
    private var selectedElementByApp: [String: AXUIElement] = [:]

    private var valueDebounceWorkItem: DispatchWorkItem?
    private var selectionDebounceWorkItem: DispatchWorkItem?
    private var parseDebounceWorkItem: DispatchWorkItem?

    private var timedOutPIDs: Set<pid_t> = []  // Track PIDs that have timed out

    // MARK: - Initializers

    private init() {}

    // MARK: - Functions

    func setModel(_ model: OnitModel) {
        self.model = model
    }

    // MARK: Start / Stop

    func start(pid: pid_t?) {
        startAppActivationObservers()
        
        guard let pid = pid else { return }
        
        // Ensure we're listening the active app on Onit launch
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        if pid == getpid() || pid.getAppName() == appName {
            print("Accessibility started with Onit process identifier")
        } else {
            handleAppActivation(appName: pid.getAppName(), processID: pid)
            startAccessibilityObservers(for: pid)
        }
    }

    func stop() {
        for pid in observers.keys {
            stopAccessibilityObservers(for: pid)
        }

        stopAppActivationObservers()

        currentSource = nil
        observers.removeAll()
    }

    private func startAppActivationObservers() {
        // Observe when any application is activated
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appActivationReceived),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil)

        // Observe when any application is deactivated
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDeactivationReceived),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil)
    }

    private func stopAppActivationObservers() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    private func startAccessibilityObservers(for pid: pid_t) {
        guard Thread.isMainThread else {
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
        var observer: AXObserver?

        let observerCallback: AXObserverCallbackWithInfo = {
            observer, element, notification, userInfo, refcon in
            // Dispatch to main thread immediately
            DispatchQueue.main.async {
                let accessibilityInstance = Unmanaged<AccessibilityNotificationsManager>
                    .fromOpaque(
                        refcon!
                    ).takeUnretainedValue()
                accessibilityInstance.handleAccessibilityNotifications(
                    notification as String, info: userInfo as! [String: Any] as Dictionary,
                    element: element, observer: observer)
            }
        }

        let result = AXObserverCreateWithInfoCallback(pid, observerCallback, &observer)

        if result == .success, let observer = observer {
            // Release the previous observer if it exists
            self.observers[pid] = observer
            let refCon = Unmanaged.passUnretained(self).toOpaque()
            for notification in Config.notifications {
                // print("Registering observer for \(notification)...")
                AXObserverAddNotification(
                    observer, pid.getAXUIElement(), notification as CFString, refCon)
            }
            // Add the observer to the main run loop
            CFRunLoopAddSource(
                CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
            print("Observer registered for PID: \(pid)")

        } else {
            AccessibilityAnalytics.logObserverError(
                errorCode: result.rawValue,
                pid: pid
            )
        }
    }

    private func stopAccessibilityObservers(for pid: pid_t) {
        // Check if the process ID is already in self.observers
        guard let existingObserver = self.observers[pid] else { return }

        let runLoopSource = AXObserverGetRunLoopSource(existingObserver)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        for notification in Config.notifications {
            AXObserverRemoveNotification(existingObserver, pid.getAXUIElement(), notification as CFString)
        }

        self.observers.removeValue(forKey: pid)
        print("Stop accessibility observers for PID: \(pid).")
    }

    // MARK: Notifications handling

    @objc private func appActivationReceived(notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
            as? NSRunningApplication
        {
            Task { @MainActor in
                // TODO: KNA - Investigate on this
                // Skip if the activated app is our own app
                // There's an edge case where the panel somehow has a different processId.
                let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                if app.processIdentifier == getpid() || app.localizedName == appName {
                    print("Ignoring activation of our own app.")
                    return
                }

                self.stopAccessibilityObservers(for: app.processIdentifier)
                self.handleAppActivation(
                    appName: app.localizedName, processID: app.processIdentifier)
                self.startAccessibilityObservers(for: app.processIdentifier)
            }
        }
    }
    
    @objc private func appDeactivationReceived(notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
            as? NSRunningApplication
        {
            print(
                "Application deactivated: \(app.localizedName ?? "Unknown") \(app.processIdentifier)"
            )

            self.stopAccessibilityObservers(for: app.processIdentifier)
        }
    }

    // MARK: Handling app activated/deactived

    private func handleAppActivation(appName: String?, processID: pid_t) {
        let selectedText = selectedTextByApp[appName ?? "Unknown"]
        let selectedElement = selectedElementByApp[appName ?? "Unknown"]

        print("\nApplication activated: \(appName ?? "Unknown") \(processID)")

        currentSource = appName
        processSelectedText(selectedText, for: selectedElement)
        handleWindowBounds(for: processID.getAXUIElement())
        parseAccessibility(for: processID)
    }

    private func handleAccessibilityNotifications(
        _ notification: String, info: [String: Any], element: AXUIElement, observer: AXObserver
    ) {
        dispatchPrecondition(condition: .onQueue(.main))

        handleExternalElement(element) { [weak self] elementPid in
            switch notification {
            case kAXFocusedUIElementChangedNotification:
                self?.handleFocusChange(for: element)
            case kAXSelectedTextChangedNotification:
                self?.handleSelectionChange(for: element)
            case kAXValueChangedNotification:
                self?.handleValueChanged(for: element)
            case kAXSelectedColumnsChangedNotification:
                print("Selected Columns Changed Notification!")
                // These handle tabbed interfaces
                self?.handleFocusChange(for: element)
            case kAXSelectedRowsChangedNotification:
                print("Selected Rows Changed Notification!")
                self?.handleFocusChange(for: element)
            case kAXWindowMovedNotification, kAXWindowResizedNotification:
                self?.handleWindowBounds(for: element)
            default:
                break
            }
        }
    }

    func handleFocusChange(for element: AXUIElement) {
        handleExternalElement(element) { [weak self] elementPid in
            print("Focus change from pid: \(elementPid)")

            self?.parseAccessibility(for: elementPid)
            self?.handleWindowBounds(for: element)
        }
    }

    func handleValueChanged(for element: AXUIElement) {
        // Filter on text area or textfield
        guard let role = element.role(), [kAXTextFieldRole, kAXTextAreaRole].contains(role) else {
            return
        }

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
    
    // MARK: - Window resize / move
    
    private func handleWindowBounds(for element: AXUIElement) {
        handleExternalElement(element) { [weak self] elementPid in
            if let window = self?.findWindow(from: element) {
                self?.activeWindowElement = window
            }
        }
    }
    
    private func findWindow(from element: AXUIElement) -> AXUIElement? {
        if let role = element.role(), role == kAXWindowRole {
            return element
        }
        
        var currentElement = element
        while true {
            guard let parent = currentElement.parent() else { break }
            
            if let role = parent.role(), role == kAXWindowRole {
                return parent
            }
            
            currentElement = parent
        }
        
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(currentElement, kAXWindowsAttribute as CFString, &value)
        
        if result == .success,
           let windows = value as? [AXUIElement],
           let window = windows.first {
            return window
        }
        
        return nil
    }

    // MARK: Parsing

    private func parseAccessibility(for pid: pid_t) {
        // Check if the PID has previously timed out
        if timedOutPIDs.contains(pid) {
            print("Skipping parsing for PID \(pid) due to previous timeout.")
            return
        }

        guard FeatureFlagManager.shared.accessibilityAutoContext else {
            self.screenResult = .init()
            return
        }
        
        parseDebounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            Task.detached(priority: .background) { [pid, weak self] in
                guard let self = self else { return }
                do {
                    var results = try await withThrowingTaskGroup(of: [String: String]?.self) { group -> [String: String]? in
                        group.addTask {
                            return await AccessibilityParser.shared.getAllTextInElement(appElement: pid.getAXUIElement())
                        }
                        group.addTask {
                            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 second timeout
                            throw NSError(domain: "AccessibilityParsingTimeout", code: 1, userInfo: nil)
                        }
                        let firstCompleted = try await group.next()!
                        group.cancelAll()
                        return firstCompleted
                    }
                    
                    let elapsedTime = results?[AccessibilityParsedElements.elapsedTime]
                    let appName = results?[AccessibilityParsedElements.applicationName]
                    let appTitle = results?[AccessibilityParsedElements.applicationTitle]
                    
                    results?.removeValue(forKey: AccessibilityParsedElements.elapsedTime)
                    results?.removeValue(forKey: AccessibilityParsedElements.applicationName)
                    results?.removeValue(forKey: AccessibilityParsedElements.applicationTitle)
                    
                    await MainActor.run {
                        self.screenResult.elapsedTime = elapsedTime
                        self.screenResult.applicationName = appName
                        self.screenResult.applicationTitle = appTitle
                        self.screenResult.others = results
                        self.screenResult.errorMessage = nil
                        self.showDebug()
                    }
                } catch {
                    let appName = pid.getAppName() ?? "Unknown"
                    await MainActor.run {
                        print("Accessibility timeout")
                        self.timedOutPIDs.insert(pid)
                        PostHogSDK.shared.capture("accessibilityParseTimedOut", properties: ["applicationName": appName])
                        self.screenResult = .init()
                        self.screenResult.errorMessage = "Timeout occurred, could not read application in reasonable amount of time."
                        self.showDebug()
                    }   
                }
            }
        }
        
        parseDebounceWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Config.debounceInterval, execute: workItem)
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
        guard FeatureFlagManager.shared.accessibilityInput,
            let selectedText = text,
            let selectedElement = element,
            !selectedText.isEmpty
        else {

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

        guard
            AXUIElementCopyAttributeValue(
                element, kAXSelectedTextRangeAttribute as CFString, &selectedRangeValue) == .success
        else {
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
            !selectedText.isEmpty
        else {
            return nil
        }

        return selectedText
    }

    /** Ensure the received `AXUIElement` is not from our process */
    private func handleExternalElement(_ element: AXUIElement, callback: @escaping (pid_t) -> Void)
    {
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

            Error Message: \(screenResult.errorMessage ?? "N/A")

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

