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
    
    // MARK: - ScreenResult

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
        var errorCode: Int32?
        var appBundleUrl: URL?
    }

    // MARK: - Properties
    
    @Published private(set) var screenResult: ScreenResult = .init()
    
    let windowsManager = AccessibilityWindowsManager()
    
    private let highlightedTextCoordinator = HighlightedTextCoordinator()

    private var currentSource: String?

    private var lastHighlightingProcessedAt: Date?

    private var valueDebounceWorkItem: DispatchWorkItem?
    private var selectionDebounceWorkItem: DispatchWorkItem?
    private var parseDebounceWorkItem: DispatchWorkItem?

    private var timedOutWindowHash: Set<UInt> = []  // Track window's hash that have timed out
    
    private var lastActiveWindowPid: pid_t?

    // MARK: - Private initializer

    private init() { }
    
    // MARK: - Delegates
    
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
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
    
    func reset() {
        windowsManager.reset()
        screenResult = .init()
        
        Task.detached {
            await self.highlightedTextCoordinator.reset()
        }
        
        currentSource = nil
        lastHighlightingProcessedAt = nil
        valueDebounceWorkItem?.cancel()
        selectionDebounceWorkItem?.cancel()
        parseDebounceWorkItem?.cancel()
        
        /// I (Kevin) don't think we should reset the timed out windows
        // timedOutWindowHash.removeAll()
        
        lastActiveWindowPid = nil
    }

    // MARK: Handling app activated/deactived

    private func handleAppActivation(appName: String?, processID: pid_t) {
        print("Application activated: \(appName ?? "Unknown") \(processID)")
         
        Task.detached {
            await self.highlightedTextCoordinator.startPollingIfNeeded(pid: processID, selectionChangedHandler: { [weak self] text, frame in
                guard let self = self else { return }
                
                Task { @MainActor in
                    self.processSelectedText(text, elementFrame: frame)
                }
            })
        }

        currentSource = appName
        lastActiveWindowPid = processID
        
        if let mainWindow = processID.firstMainWindow {
            handleWindowBounds(for: mainWindow, elementPid: processID)
        }
    }
    
    private func handleAppDeactivation(appName: String?, processID: pid_t) {
        print("Application deactivated: \(appName ?? "Unknown") \(processID)")
        
        Task.detached {
            await self.highlightedTextCoordinator.stopPolling(pid: processID)
        }
    }

    func handleAccessibilityNotifications(
        _ notification: String, info: [String: Any], element: AXUIElement, elementPid: pid_t
    ) {
        dispatchPrecondition(condition: .onQueue(.main))
        
        log.debug("Received notification: \(notification) \(element.role() ?? "") \(element.title() ?? "")")
        switch notification {
        case kAXFocusedWindowChangedNotification, kAXMainWindowChangedNotification:
            self.handleWindowBounds(for: element, elementPid: elementPid)
        case kAXSelectedTextChangedNotification:
            self.handleSelectionChange(for: element)
        case kAXValueChangedNotification:
            self.handleValueChanged(for: element)
        case kAXWindowMovedNotification:
            self.handleWindowMoved(for: element, elementPid: elementPid)
        case kAXWindowResizedNotification:
            self.handleWindowResized(for: element, elementPid: elementPid)
        case kAXWindowCreatedNotification:
            self.handleCreatedWindowElement(for: element, elementPid: elementPid)
        case kAXUIElementDestroyedNotification:
            self.handleDetroyedElement(for: element)
        case kAXWindowMiniaturizedNotification:
            self.handleMinimizedElement(for: element)
        case kAXWindowDeminiaturizedNotification:
            self.handleDeminimizedElement(for: element)
        case kAXTitleChangedNotification:
            self.handleTitleChanged(for: element, elementPid: elementPid)
        default:
            break
        }
    }
    
    private func handleTitleChanged(for element: AXUIElement, elementPid: pid_t) {
        guard let trackedWindow = self.windowsManager.trackWindowForElement(element, pid: elementPid) else { return }
        
        notifyDelegates { $0.accessibilityManager(self, didChangeWindowTitle: trackedWindow) }
    }
    
    private func handleWindowMoved(for element: AXUIElement, elementPid: pid_t) {
        guard let trackedWindow = self.windowsManager.trackWindowForElement(element, pid: elementPid) else { return }
        
        notifyDelegates { $0.accessibilityManager(self, didMoveWindow: trackedWindow) }
    }
    
    private func handleWindowResized(for element: AXUIElement, elementPid: pid_t) {
        guard let trackedWindow = self.windowsManager.trackWindowForElement(element, pid: elementPid) else { return }
        
        notifyDelegates { $0.accessibilityManager(self, didResizeWindow: trackedWindow) }
    }
    
    private func handleWindowBounds(for element: AXUIElement, elementPid: pid_t) {
        guard let trackedWindow = self.windowsManager.trackWindowForElement(element, pid: elementPid) else { return }
        
        notifyDelegates { $0.accessibilityManager(self, didActivateWindow: trackedWindow) }
    }
    
    private func handleCreatedWindowElement(for element: AXUIElement, elementPid: pid_t) {
        guard let trackedWindow = self.windowsManager.trackWindowForElement(element, pid: elementPid) else { return }
        
        self.notifyDelegates { $0.accessibilityManager(self, didActivateWindow: trackedWindow) }
    }
    
    private func handleDetroyedElement(for element: AXUIElement) {
        let foundWindows = self.windowsManager.trackedWindows(for: element)
        
        for foundWindow in foundWindows {
            if foundWindow.element.role() == nil {
                guard let trackedWindow = self.windowsManager.remove(foundWindow) else { return }
                
                notifyDelegates { $0.accessibilityManager(self, didDestroyWindow: trackedWindow) }
            }
        }
    }
    
    private func handleMinimizedElement(for element: AXUIElement) {
        let trackedWindows = self.windowsManager.trackedWindows(for: element)
        if let firstTrackedWindow = trackedWindows.first {
            notifyDelegates { delegate in
                delegate.accessibilityManager(self, didMinimizeWindow: firstTrackedWindow)
            }
        }
    }
    
    private func handleDeminimizedElement(for element: AXUIElement) {
        let trackedWindows = self.windowsManager.trackedWindows(for: element)
        if let firstTrackedWindow = trackedWindows.first {
            notifyDelegates { delegate in
                delegate.accessibilityManager(self, didDeminimizeWindow: firstTrackedWindow)
            }
        }
    }

    private func handleValueChanged(for element: AXUIElement) {
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
        guard HighlightedTextValidator.isValid(element: element) else { return }
        
        // Fix to work with PDF in Chrome
        if let lastHighlightingProcessedAt = lastHighlightingProcessedAt, Date().timeIntervalSince(lastHighlightingProcessedAt) < 0.002 {
            return
        }
        
        lastHighlightingProcessedAt = Date()
        selectionDebounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.processSelectionChange(for: element)
        }

        selectionDebounceWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + Config.debounceInterval, execute: workItem)
    }
    
    // MARK: Parsing
    
    func retrieveWindowContent(
        pid: pid_t? = nil,
        state: OnitPanelState? = nil,
        trackedWindow: TrackedWindow? = nil,
        customAppBundleUrl: URL? = nil
    ) {
        guard let pid = trackedWindow?.pid ?? pid ?? lastActiveWindowPid,
              let mainWindow = trackedWindow?.element ?? pid.firstMainWindow,
              let state = state ?? PanelStateCoordinator.shared.getState(for: CFHash(mainWindow))
        else {
            return
        }
        
        let windowHash = trackedWindow?.hash ?? CFHash(mainWindow)
        
        state.windowContextTasks[windowHash]?.cancel()
        
        // This task will automatically be cleaned up way down the call stack when it hits `addAutoContext()`.
        state.windowContextTasks[windowHash] = Task {
            if let documentInfo = findDocument(in: mainWindow) {
                handleWindowContent(
                    documentInfo,
                    for: state,
                    trackedWindow: trackedWindow,
                    customAppBundleUrl: customAppBundleUrl
                )
                // TODO: KNA - uncomment this to use WebContentFetchService with AXURL
            } else if let url = findUrl(in: mainWindow), url.absoluteString.contains("docs.google.com") {
                
                let appName = mainWindow.parent()?.title() ?? ""
                let appTitle = mainWindow.title() ?? ""
                let startTime = CFAbsoluteTimeGetCurrent()
                if GoogleDriveService.shared.checkAuthorizationStatus() {
                    do {
                        let documentContent = try await GoogleDriveService.shared.extractTextFromGoogleDrive(driveUrl: url.absoluteString)
                        let contentArray = [
                            AccessibilityParsedElements.applicationName: appName,
                            AccessibilityParsedElements.applicationTitle: appTitle,
                            AccessibilityParsedElements.elapsedTime: "\(CFAbsoluteTimeGetCurrent() - startTime)",
                            "document": documentContent
                        ]
                        handleWindowContent(
                            contentArray,
                            for: state,
                            customAppBundleUrl: customAppBundleUrl
                        )
                    } catch {
                        // Handle error case
                        var appBundleUrl = customAppBundleUrl
                        if appBundleUrl == nil {
                            if let pid = lastActiveWindowPid,
                            let app = NSRunningApplication(processIdentifier: pid) {
                                appBundleUrl = app.bundleURL
                            }
                        }
                        self.screenResult = .init()
                        self.screenResult.applicationName = appName
                        self.screenResult.applicationTitle = appTitle
                        self.screenResult.appBundleUrl = appBundleUrl
                        if let googleDriveError = error as? GoogleDriveServiceError {
                            self.screenResult.errorMessage = "\(googleDriveError.localizedDescription)"
                            switch googleDriveError {
                            case .notFound:
                                self.screenResult.errorCode = 1501
                                break
                            default:
                                self.screenResult.errorCode = 1500
                            }
                        } else {
                            self.screenResult.errorMessage = "Failed to extract Google Drive document content: \(error.localizedDescription)"
                            self.screenResult.errorCode = 1500
                        }
                        state.addAutoContext(trackedWindow: trackedWindow)
                    }
                } else {
                    // This creates an error state for when google drive is not authorized
                    var appBundleUrl = customAppBundleUrl
                    if appBundleUrl == nil {
                        if let pid = lastActiveWindowPid,
                        let app = NSRunningApplication(processIdentifier: pid) {
                            appBundleUrl = app.bundleURL
                        }
                    }
                    self.screenResult = .init()
                    self.screenResult.applicationName = appName
                    self.screenResult.applicationTitle = appTitle
                    self.screenResult.appBundleUrl = appBundleUrl
                    self.screenResult.errorMessage = "Google Drive Plugin Required"
                    self.screenResult.errorCode = 1500
                    state.addAutoContext(trackedWindow: trackedWindow)
                }
            }  else {
                parseAccessibility(
                    for: pid,
                    in: mainWindow,
                    state: state,
                    trackedWindow: trackedWindow,
                    customAppBundleUrl: customAppBundleUrl
                )
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
    
    private func findUrl(in element: AXUIElement, maxDepth: Int = 5) -> URL? {
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
        return findURLInChildren(element: element)
    }
    
    private func findUrlAndProcessURL(in focusedWindow: AXUIElement) async -> [String: String]? {
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
        
        if let url = findUrl(in: focusedWindow) {
            return await processUrl(url, from: focusedWindow)
        }
        return nil
    }

    private func parseAccessibility(
        for pid: pid_t,
        in window: AXUIElement,
        state: OnitPanelState,
        trackedWindow: TrackedWindow? = nil,
        customAppBundleUrl: URL? = nil
    ) {
        let windowHash = trackedWindow?.hash ?? CFHash(window)
        let appName = trackedWindow?.element.parent()?.title() ?? window.parent()?.title() ?? "Unknown"
        let mainWindow = trackedWindow?.element ?? window
        
        if timedOutWindowHash.contains(windowHash) {
            print("Skipping parsing for window's hash \(windowHash) due to previous timeout.")
            return
        }
        
        guard Defaults[.autoContextFromCurrentWindow] else {
            self.screenResult = .init()
            return
        }
        
        parseDebounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            Task {
                do {
                    let (results, boundingBoxes) = try await AccessibilityParser.shared.getAllTextInElement(windowElement: mainWindow)
                    self.handleWindowContent(
                        results,
                        for: state,
                        trackedWindow: trackedWindow,
                        customAppBundleUrl: customAppBundleUrl
                    )
                } catch {
                    await MainActor.run {
                        print("Accessibility timeout")
                        self.timedOutWindowHash.insert(windowHash)
                        AnalyticsManager.Accessibility.parseTimedOut(appName: appName)
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
    
    private func handleWindowContent(
        _ results: [String: String]?,
        for state: OnitPanelState,
        trackedWindow: TrackedWindow? = nil,
        customAppBundleUrl: URL? = nil
    ) {
        var appBundleUrl: URL? = customAppBundleUrl
        
        if appBundleUrl == nil,
           let pid = lastActiveWindowPid,
           let app = NSRunningApplication(processIdentifier: pid)
        {
            appBundleUrl = app.bundleURL
        }
        
        let elapsedTime = results?[AccessibilityParsedElements.elapsedTime]
        let appName = results?[AccessibilityParsedElements.applicationName]
        let appTitle = results?[AccessibilityParsedElements.applicationTitle]
        let highlightedText = results?[AccessibilityParsedElements.highlightedText]
        
        var results = results
        
        results?.removeValue(forKey: AccessibilityParsedElements.elapsedTime)
        results?.removeValue(forKey: AccessibilityParsedElements.applicationName)
        results?.removeValue(forKey: AccessibilityParsedElements.applicationTitle)
        results?.removeValue(forKey: AccessibilityParsedElements.highlightedText)
        
        self.screenResult.elapsedTime = elapsedTime
        self.screenResult.applicationName = appName
        self.screenResult.applicationTitle = appTitle
        self.screenResult.others = results
        self.screenResult.errorMessage = nil
        self.screenResult.appBundleUrl = appBundleUrl
        self.showDebug()
        
        state.addAutoContext(trackedWindow: trackedWindow)
    }

    // MARK: Value Changed

    private func processValueChanged(for element: AXUIElement) {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))

        guard let value = element.value() else {
            screenResult.userInteraction.input = nil
            showDebug()
            return
        }

        screenResult.userInteraction.input = value
        showDebug()
    }

    // MARK: Text Selection

    private func processSelectionChange(for element: AXUIElement) {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))

        let selectedTextExtracted = element.selectedText()
        let elementBounds = element.selectedTextBound()
        
        processSelectedText(selectedTextExtracted, elementFrame: elementBounds)
        showDebug()
    }

    private func processSelectedText(_ text: String?, elementFrame: CGRect?) {
        guard Defaults[.autoContextFromHighlights],
              let selectedText = text,
              HighlightedTextValidator.isValid(text: selectedText) else {
            
            PanelStateCoordinator.shared.state.pendingInput = nil
            return
        }
        
        screenResult.userInteraction.selectedText = selectedText
        
        let input = Input(selectedText: selectedText, application: currentSource ?? "")
        PanelStateCoordinator.shared.state.pendingInput = input
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
}

// MARK: - AccessibilityObserversDelegate

extension AccessibilityNotificationsManager: AccessibilityObserversDelegate {
    func accessibilityObserversManager(didActivateApplication appName: String?, processID: pid_t) {
        handleAppActivation(appName: appName, processID: processID)
    }
    
    func accessibilityObserversManager(didActivateIgnoredApplication appName: String?) {
        notifyDelegates { delegate in
            delegate.accessibilityManager(self, didActivateIgnoredWindow: nil)
        }
    }
    
    func accessibilityObserversManager(didReceiveNotification notification: String, element: AXUIElement, elementPid: pid_t, info: [String: Any]) {
        handleAccessibilityNotifications(notification, info: info, element: element, elementPid: elementPid)
    }
    
    func accessibilityObserversManager(didDeactivateApplication appName: String?, processID: pid_t) {
        handleAppDeactivation(appName: appName, processID: processID)
    }
}
