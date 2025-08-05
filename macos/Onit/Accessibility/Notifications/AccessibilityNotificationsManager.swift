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
    
    // MARK: - Properties
    
    let windowsManager = AccessibilityWindowsManager()
    
    private let highlightedTextCoordinator = HighlightedTextCoordinator()
    
    private let caretPositionManager = CaretPositionManager.shared

    private var currentSource: String?

    private var lastHighlightingProcessedAt: Date?
    private var lastCaretPositionChangeTimestamp: Date?

    private var valueDebounceWorkItem: DispatchWorkItem?
    private var selectionDebounceWorkItem: DispatchWorkItem?
    private var parseDebounceWorkItem: DispatchWorkItem?
    
    // Published property for selected text that QuickEditManager can observe
    @Published var selectedText: String?

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

    /// Notifies delegates with filtering based on element's process type
    private func notifyDelegates(for element: AXUIElement, _ notification: (AccessibilityNotificationsDelegate) -> Void) {
       guard let elementPid = element.pid() else {
           // If we can't determine PID, notify all delegates
           notifyDelegates(notification)
           return
       }

       let processType = determineProcessType(for: elementPid)

       for case let delegate as AccessibilityNotificationsDelegate in delegates.allObjects {
           switch processType {
           case .ownProcess:
               if delegate.wantsNotificationsFromOnit {
                   notification(delegate)
               }
           case .ignoreProcess:
               if delegate.wantsNotificationsFromIgnoredProcesses {
                   notification(delegate)
               }
           case .eligible:
               notification(delegate)
           }
       }
   }

   /// Determines the process type for a given PID using shared logic from AccessibilityObserversManager
   private func determineProcessType(for pid: pid_t) -> ProcessObservationEligibility {
       return AccessibilityObserversManager.determineProcessObservationEligibility(
           for: pid,
           ignoredAppNames: AccessibilityObserversManager.currentIgnoredAppNames
       )
   }
    
    // MARK: - Functions
    
    func hasAnyDelegateWantingIgnoredProcesses() -> Bool {
        for case let delegate as AccessibilityNotificationsDelegate in delegates.allObjects {
            if delegate.wantsNotificationsFromIgnoredProcesses {
                return true
            }
        }
        return false
    }
    
    func reset() {
        windowsManager.reset()
        
        Task.detached {
            await self.highlightedTextCoordinator.reset()
        }
        
        currentSource = nil
        lastHighlightingProcessedAt = nil
		lastCaretPositionChangeTimestamp = nil
        valueDebounceWorkItem?.cancel()
        selectionDebounceWorkItem?.cancel()
        parseDebounceWorkItem?.cancel()
        
        selectedText = nil
        
        ContextFetchingService.shared.reset()
    }

    // MARK: Handling app activated/deactived

    private func handleAppActivation(appName: String?, processID: pid_t) {
        print("Application activated: \(appName ?? "Unknown") \(processID)")
         
        Task.detached {
            await self.highlightedTextCoordinator.startPollingIfNeeded(pid: processID, selectionChangedHandler: { [weak self] element, text in
                guard let self = self else { return }
                nonisolated(unsafe) let unsafeElement = element
                
                Task { @MainActor in
                    if let element = unsafeElement {
                        self.processSelectionChange(for: element)
                    } else {
                        // Handle text deselection - clear pendingInput
                        self.processSelectedText(nil)
                    }
                }
            })
        }

        currentSource = appName
        ContextFetchingService.shared.setLastActive(windowPid: processID)
        
        caretPositionManager.updateCaretLost()
        
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
            // self.handleCaretPositionChange(for: element)
        case kAXFocusedUIElementChangedNotification:
            self.handleCaretPositionChange(for: element)
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

        DispatchQueue.main.asyncAfter(deadline: .now() + Config.textSelectionDebounceInterval, execute: workItem)
    }

    // MARK: Value Changed

    private func processValueChanged(for element: AXUIElement) {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))

        guard let value = element.value() else {
            showDebug()
            return
        }

        showDebug()
    }

    // MARK: Text Selection

    private func processSelectionChange(for element: AXUIElement) {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))

        let selectedText = element.selectedText()
        
        if let selectedText = selectedText, HighlightedTextValidator.isValid(text: selectedText) {
            Task {
                _ = await HighlightedTextBoundsExtractor.shared.getBounds(for: element, selectedText: selectedText)
                
                processSelectedText(selectedText)
            }
        } else {
            // On every apps, when caret position changed, we receive AXSelectedTextChanged notification with nil value.
            // This code is used to hide the QuickEdit hint for a real deselection
            let now = Date()
            let caretPositionChangeRecently = now.timeIntervalSince(lastCaretPositionChangeTimestamp ?? .distantPast) < 0.5 
            let isEditableField = element.role() == kAXTextFieldRole || element.role() == kAXTextAreaRole
            
            if !caretPositionChangeRecently && !isEditableField {
                processSelectedText(nil)
                HighlightedTextBoundsExtractor.shared.reset()
                QuickEditManager.shared.hideHint()
            } else if isEditableField {
                handleCaretPositionChange(for: element)
            }
        }
        
        showDebug()
    }

    private func processSelectedText(_ text: String?) {
        guard Defaults[.autoContextFromHighlights],
              let selectedText = text,
              HighlightedTextValidator.isValid(text: selectedText) else {
            
            PanelStateCoordinator.shared.state.pendingInput = nil
            PanelStateCoordinator.shared.state.trackedPendingInput = nil
            self.selectedText = nil
            return
        }
        
        // Update the published selectedText property
        self.selectedText = selectedText

        let input = Input(selectedText: selectedText, application: currentSource ?? "")
        
        if Defaults[.autoAddHighlightedTextToContext] {
            PanelStateCoordinator.shared.state.pendingInput = input
        } else {
            PanelStateCoordinator.shared.state.trackedPendingInput = input
        }
    }

	// MARK: Caret Position Handling
    
    private func handleCaretPositionChange(for element: AXUIElement) {
        guard element.supportsCaretTracking() else { return }
        
        selectionDebounceWorkItem?.cancel()
        selectionDebounceWorkItem = nil
        processSelectedText(nil)
		lastCaretPositionChangeTimestamp = Date()
        caretPositionManager.updateCaretPosition(for: element)
    }

    // MARK: Debug

    private func showDebug() {
        // Debug information is now handled by ContextFetchingService
        DebugManager.shared.debugText = "Debug information moved to ContextFetchingService"
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
    
    func accessibilityObserversManager(didActivateIgnoredApplication appName: String?, processID: pid_t) { }

    func accessibilityObserversManager(didDeactivateIgnoredApplication appName: String?, processID: pid_t) { }

    func accessibilityObserversManager(didActivateOnit processID: pid_t) { }
    
    func accessibilityObserversManager(didDeactivateOnit processID: pid_t) { }
}
