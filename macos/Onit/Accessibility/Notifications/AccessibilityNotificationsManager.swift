//
//  AccessibilityNotificationsManager.swift
//  Onit
//
//  Created by Kévin Naudin on 22/01/2025.
//

import ApplicationServices
import Defaults
import Foundation
import PostHog
import SwiftUI

@MainActor
class AccessibilityNotificationsManager: ObservableObject {

    // MARK: - Singleton instance

    static let shared = AccessibilityNotificationsManager()

    let windowsManager = AccessibilityWindowsManager()
    
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
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
        var errorMessage: String?  // Renamed field for error message
    }

    // MARK: - Properties

    private var currentSource: String?

    // Transient observers that are started and stopped on app activation/deactivation.
    private var observers: [pid_t: AXObserver] = [:]
    
    // Persistent observers that are started once per pid and remain until the app quits.
    private var persistentObservers: [pid_t: AXObserver] = [:]
    
    private var selectedSource: String?

    private var selectedTextByApp: [String: String] = [:]
    private var selectedElementByApp: [String: AXUIElement] = [:]

    private var valueDebounceWorkItem: DispatchWorkItem?
    private var selectionDebounceWorkItem: DispatchWorkItem?
    private var parseDebounceWorkItem: DispatchWorkItem?

    private var timedOutWindowHash: Set<UInt> = []  // Track window's hash that have timed out

    #if DEBUG
    private let ignoredAppNames : [String] = ["Xcode"]
    #else
    private let ignoredAppNames : [String] = []
    #endif

    // MARK: - Initializers

    private init() { }
    
    // MARK: - Delegates
    
    func addDelegate(_ delegate: AccessibilityNotificationsDelegate) {
        delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate: AccessibilityNotificationsDelegate) {
        delegates.remove(delegate)
    }
    
    private func notifyDelegates(_ notification: (AccessibilityNotificationsDelegate) -> Void) {
        for case let delegate as AccessibilityNotificationsDelegate in delegates.allObjects {
            notification(delegate)
        }
    }

    // MARK: - Functions

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
            startPersistentAccessibilityObservers(for: pid) // Start persistent observer
        }
    }

    func stop() {
        for pid in observers.keys {
            stopAccessibilityObservers(for: pid)
        }

        stopAppActivationObservers()

        currentSource = nil
        observers.removeAll()
        // Note: Persistent observers are kept until app quits. Optionally, uncomment the following if a cleanup is desired.
        // stopPersistentAccessibilityObservers()
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
        
        // Skip if the PID is our own process or an ignored app
        if pid == getpid() {
            print("Not setting up observer for our own process")
        } else if ignoredAppNames.contains(pid.getAppName() ?? "") {
            print("Not setting up observer for ignored app: \(pid.getAppName() ?? "Unknown")")
            notifyDelegates { delegate in
                delegate.accessibilityManager(self, didActivateIgnoredWindow: nil)
            }
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
                // I'm also added ignore logic for Xcode because it makes it hard to debug if the process changes everytime a breakpoint is hit. 
                let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                if app.processIdentifier == getpid() || 
                    app.localizedName == appName {
                    print("Ignoring activation of our own app")
                    return
                } else if ignoredAppNames.contains(app.localizedName ?? "") {
                    print("Ignoring activation of ignored app: \(app.localizedName ?? "Unknown")")
                    notifyDelegates { delegate in
                        delegate.accessibilityManager(self, didActivateIgnoredWindow: nil)
                    }
                    return
                }

                self.stopAccessibilityObservers(for: app.processIdentifier)
                self.handleAppActivation(
                    appName: app.localizedName, processID: app.processIdentifier)
                self.startAccessibilityObservers(for: app.processIdentifier)
                self.startPersistentAccessibilityObservers(for: app.processIdentifier) // Start persistent observer on activation
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
        if let targetWindow = processID.getAXUIElement().findFirstTargetWindow() {
            handleWindowBounds(for: targetWindow)
        }
        processSelectedText(selectedText, for: selectedElement)
        retrieveWindowContent(for: processID)
    }

    private func handleAccessibilityNotifications(
        _ notification: String, info: [String: Any], element: AXUIElement, observer: AXObserver
    ) {
        dispatchPrecondition(condition: .onQueue(.main))

        handleExternalElement(element) { [weak self] elementPid in
            guard let self = self else { return }
            
            log.debug("Received notification: \(notification) \(element.role() ?? "") \(element.title() ?? "")")
            switch notification {
            case kAXFocusedWindowChangedNotification, kAXMainWindowChangedNotification:
                self.handleWindowBounds(for: element)
            case kAXFocusedUIElementChangedNotification, kAXSelectedColumnsChangedNotification, kAXSelectedRowsChangedNotification:
                self.handleFocusChange(for: element)
            case kAXSelectedTextChangedNotification:
                self.handleSelectionChange(for: element)
            case kAXValueChangedNotification:
                self.handleValueChanged(for: element)
            case kAXWindowMovedNotification:
                self.handleWindowMoved(for: element)
            case kAXWindowResizedNotification:
                self.handleWindowResized(for: element)
            case kAXWindowCreatedNotification:
                self.handleCreatedWindowElement(for: element)
            case kAXUIElementDestroyedNotification:
                self.handleDetroyedElement(for: element)
            default:
                break
            }
        }
    }
    
    private func handleWindowMoved(for element: AXUIElement) {
        handleExternalElement(element) { [weak self] elementPid in
            guard let self = self,
                  let trackedWindow = self.windowsManager.append(element, pid: elementPid) else { return }
            
            notifyDelegates { $0.accessibilityManager(self, didMoveWindow: trackedWindow) }
        }
    }
    
    private func handleWindowResized(for element: AXUIElement) {
        handleExternalElement(element) { [weak self] elementPid in
            guard let self = self,
                  let trackedWindow = self.windowsManager.append(element, pid: elementPid) else { return }
            
            notifyDelegates { $0.accessibilityManager(self, didResizeWindow: trackedWindow) }
        }
    }
    
    private func handleWindowBounds(for element: AXUIElement) {
        handleExternalElement(element) { [weak self] elementPid in
            guard let self = self,
                  let trackedWindow = self.windowsManager.append(element, pid: elementPid) else { return }
            
            notifyDelegates { $0.accessibilityManager(self, didActivateWindow: trackedWindow) }
        }
    }
    
    func handleCreatedWindowElement(for element: AXUIElement) {
        handleExternalElement(element) { [weak self] elementPid in
            guard let self = self,
                  let trackedWindow = self.windowsManager.append(element, pid: elementPid) else { return }
            
            self.notifyDelegates { $0.accessibilityManager(self, didActivateWindow: trackedWindow) }
        }
    }
    
    func handleDetroyedElement(for element: AXUIElement) {
        handleExternalElement(element) { [weak self] elementPid in
            guard let self = self else { return }
            
            let foundWindows = self.windowsManager.trackedWindows(for: element)
            
            for foundWindow in foundWindows {
                if foundWindow.element.role() == nil {
                    guard let trackedWindow = self.windowsManager.remove(foundWindow) else { return }
                    
                    notifyDelegates { $0.accessibilityManager(self, didDestroyWindow: trackedWindow) }
                }
            }
        }
    }
    
    func handleMinimizedElement(for element: AXUIElement) {
        let trackedWindows = self.windowsManager.trackedWindows(for: element)
        if let firstTrackedWindow = trackedWindows.first {
            notifyDelegates { delegate in
                delegate.accessibilityManager(self, didMinimizeWindow: firstTrackedWindow)
            }
        }
    }
    
    func handleDeminimizedElement(for element: AXUIElement) {
        let trackedWindows = self.windowsManager.trackedWindows(for: element)
        if let firstTrackedWindow = trackedWindows.first {
            notifyDelegates { delegate in
                delegate.accessibilityManager(self, didDeminimizeWindow: firstTrackedWindow)
            }
        }
    }

    func handleFocusChange(for element: AXUIElement) {
        handleExternalElement(element) { [weak self] elementPid in
            print("Focus change from pid: \(elementPid)")
            self?.retrieveWindowContent(for: elementPid)
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
    
    // MARK: Parsing
    
    private func retrieveWindowContent(for pid: pid_t) {
        guard let focusedWindow = pid.getFocusedWindow() else { return }
        
        if let (_, state) = TetherAppsManager.shared.states.first(where: { $0.key.hash == CFHash(focusedWindow) }) {
            Task { @MainActor in
                if let documentInfo = findDocument(in: focusedWindow) {
                    handleWindowContent(documentInfo, for: state)
                    // TODO: KNA - uncomment this to use WebContentFetchService with AXURL
                } /* else if let urlInfo = await findUrl(in: focusedWindow) {
                    handleWindowContent(urlInfo, for: state)
                } */ else {
                    parseAccessibility(for: pid, in: focusedWindow, state: state)
                }
            }
        }
    }
    
    private func findDocument(in focusedWindow: AXUIElement) -> [String: String]? {
        let startTime = CFAbsoluteTimeGetCurrent()
        var documentValue: CFTypeRef?
        
        let hasDocument = AXUIElementCopyAttributeValue(focusedWindow, kAXDocumentAttribute as CFString, &documentValue) == .success
        
        if hasDocument, let document = documentValue as? String,
            document.hasPrefix("file:///"), let fileURL = URL(string: document) {
            do {
                let appName = focusedWindow.parent()?.title() ?? ""
                let appTitle = focusedWindow.title() ?? ""
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                
                return [
                    AccessibilityParsedElements.applicationName: appName,
                    AccessibilityParsedElements.applicationTitle: appTitle,
                    AccessibilityParsedElements.elapsedTime: "\(CFAbsoluteTimeGetCurrent() - startTime)",
                    "document": content
                ]
            } catch {
                return nil
            }
        }
        
        return nil
    }
    
    private func findUrl(in focusedWindow: AXUIElement) async -> [String: String]? {
        func findURLInChildren(element: AXUIElement, depth: Int = 0) -> URL? {
            if depth >= maxDepth {
                return nil
            }
            
            if let children = element.children() {
                for child in children {
                    if child.role() == "AXWebArea", let url = child.url() {
                        return url
                    }
                    
                    if let url = findURLInChildren(element: child, depth: depth + 1) {
                        return url
                    }
                }
            }
            
            return nil
        }
        
        func processUrl(_ url: URL, from element: AXUIElement) async -> [String: String]? {
            do {
                let appName = element.parent()?.title() ?? ""
                let appTitle = element.title() ?? ""
                
                let (_, content) = try await WebContentFetchService.fetchWebpageContent(websiteUrl: url)
                
                return [
                    AccessibilityParsedElements.applicationName: appName,
                    AccessibilityParsedElements.applicationTitle: appTitle,
                    AccessibilityParsedElements.elapsedTime: "\(CFAbsoluteTimeGetCurrent() - startTime)",
                    "url": url.absoluteString,
                    "content": content
                ]
            } catch {
                print("Error fetching webpage content: \(error)")
                return nil
            }
        }
        
        let maxDepth = 5
        let startTime = CFAbsoluteTimeGetCurrent()
        
        if let url = findURLInChildren(element: focusedWindow) {
            return await processUrl(url, from: focusedWindow)
        }
        
        return nil
    }

    private func parseAccessibility(for pid: pid_t, in window: AXUIElement, state: OnitPanelState) {
        let windowHash = CFHash(window)
        let appName = window.parent()?.title() ?? "Unknown"
        
        if timedOutWindowHash.contains(windowHash) {
            print("Skipping parsing for window's hash \(windowHash) due to previous timeout.")
            return
        }

        guard FeatureFlagManager.shared.accessibilityAutoContext else {
            self.screenResult = .init()
            return
        }
        
        parseDebounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            Task.detached(priority: .background) { [weak self] in
                guard let self = self else { return }
                
                do {
                    let results = try await withThrowingTaskGroup(of: [String: String]?.self) { group -> [String: String]? in
                        group.addTask {
                            guard let focusedWindow = pid.getFocusedWindow() else { return nil }
                            
                            return await AccessibilityParser.shared.getAllTextInElement(windowElement: focusedWindow)
                        }
                        group.addTask {
                            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 second timeout
                            throw NSError(domain: "AccessibilityParsingTimeout", code: 1, userInfo: nil)
                        }
                        let firstCompleted = try await group.next()!
                        group.cancelAll()
                        return firstCompleted
                    }
                    
                    await MainActor.run {
                        self.handleWindowContent(results, for: state)
                    }
                } catch {
                    await MainActor.run {
                        print("Accessibility timeout")
                        self.timedOutWindowHash.insert(windowHash)
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
    
    private func handleWindowContent(_ results: [String: String]?, for state: OnitPanelState) {
        let elapsedTime = results?[AccessibilityParsedElements.elapsedTime]
        let appName = results?[AccessibilityParsedElements.applicationName]
        let appTitle = results?[AccessibilityParsedElements.applicationTitle]
        var results = results
        
        results?.removeValue(forKey: AccessibilityParsedElements.elapsedTime)
        results?.removeValue(forKey: AccessibilityParsedElements.applicationName)
        results?.removeValue(forKey: AccessibilityParsedElements.applicationTitle)
        
        self.screenResult.elapsedTime = elapsedTime
        self.screenResult.applicationName = appName
        self.screenResult.applicationTitle = appTitle
        self.screenResult.others = results
        self.screenResult.errorMessage = nil
        self.showDebug()
        
        if Defaults[.automaticallyAddAutoContext] && results != nil {
            state.addAutoContext()
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
        guard FeatureFlagManager.shared.accessibilityInput,
            let selectedText = text,
            let selectedElement = element,
            !selectedText.isEmpty
        else {

            selectedSource = nil
            TetherAppsManager.shared.state.pendingInput = nil
            HighlightHintWindowController.shared.hide()

            return
        }
        screenResult.userInteraction.selectedText = selectedText

        selectedSource = currentSource

        let bound = selectedElement.selectedTextBound()
        HighlightHintWindowController.shared.show(bound)

        TetherAppsManager.shared.state.pendingInput = Input(selectedText: selectedText, application: currentSource ?? "")
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

        DebugManager.shared.debugText = debugText
    }

    // MARK: - Persistent Observer Methods

    /// Starts a persistent AXObserver for the given process identifier that listens for persistentNotifications.
    private func startPersistentAccessibilityObservers(for pid: pid_t) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.startPersistentAccessibilityObservers(for: pid)
            }
            return
        }
        // Skip if observer already exists.
        if persistentObservers[pid] != nil {
            return
        }
        if pid == getpid() {
            print("Not setting up persistent observer for our own process")
            return
        }
        
        print("Start persistent observer for PID: \(pid)")
        var observer: AXObserver?
        let persistentObserverCallback: AXObserverCallbackWithInfo = { observer, element, notification, userInfo, refcon in
            DispatchQueue.main.async {
                let instance = Unmanaged<AccessibilityNotificationsManager>.fromOpaque(refcon!).takeUnretainedValue()
                instance.handlePersistentAccessibilityNotifications(notification as String, info: userInfo as! [String: Any], element: element, observer: observer)
            }
        }
        let result = AXObserverCreateWithInfoCallback(pid, persistentObserverCallback, &observer)
        if result == .success, let observer = observer {
            persistentObservers[pid] = observer
            let refCon = Unmanaged.passUnretained(self).toOpaque()
            for notification in Config.persistentNotifications {
                AXObserverAddNotification(
                    observer,
                    pid.getAXUIElement(),
                    notification as CFString,
                    refCon)
            }
            CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
            print("Persistent observer registered for PID: \(pid)")
        } else {
            AccessibilityAnalytics.logObserverError(
                errorCode: result.rawValue,
                pid: pid
            )
        }
    }
    
    /// Handles the notifications received by the persistent observer.
    private func handlePersistentAccessibilityNotifications(
        _ notification: String, info: [String: Any], element: AXUIElement, observer: AXObserver
    ) {
        // Handle persistent notifications as needed.
        // For now, we simply log them. You could also notify a different delegate method if required.
        handleExternalElement(element) { [weak self] elementPid in
            guard let self = self else { return }
            print("Received Persistent notification: \(notification)")
            switch notification {
            case kAXWindowMiniaturizedNotification:
                handleMinimizedElement(for: element)
            case kAXWindowDeminiaturizedNotification:
                handleDeminimizedElement(for: element)
            default:
                break
            }
        }
    }
    
    /// Optionally, stops all persistent observers (for example, when the app is quitting).
    private func stopPersistentAccessibilityObservers() {
        for (pid, observer) in persistentObservers {
            let runLoopSource = AXObserverGetRunLoopSource(observer)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
            for notification in Config.persistentNotifications {
                AXObserverRemoveNotification(observer, pid.getAXUIElement(), notification as CFString)
            }
        }
        persistentObservers.removeAll()
    }
    
    deinit {
//        stopPersistentAccessibilityObservers()
    }
}
