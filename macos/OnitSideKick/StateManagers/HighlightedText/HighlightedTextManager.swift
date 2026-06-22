//
//  HighlightedTextManager.swift
//  Onit
//
//  Created by TimL on 07/29/2025.
//

import ApplicationServices
import Defaults
import Foundation
import SwiftUI

@MainActor
class HighlightedTextManager: ObservableObject {
    
    // MARK: - Singleton instance
    
    static let shared = HighlightedTextManager()
    
    // MARK: - Properties
    
    private var lastHighlightingProcessedAt: Date?
    private var selectionDebounceWorkItem: DispatchWorkItem?
    private var currentSource: String?
    private var lastCursorPositionChangeTimestamp: Date?
    
    // Published property for selected text that observers can subscribe to
    @Published var selectedText: String?
    
    // Published property for the element that contains the selected text
    @Published var selectedTextElement: AXUIElement?
    
    // MARK: - Delegates
    
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
    // MARK: - Private initializer
    
    private init() {
        AccessibilityNotificationsManager.shared.addDelegate(self)
    }
    
    // MARK: - AccessibilityNotificationsDelegate
    
    var wantsNotificationsFromIgnoredProcesses: Bool { false }
    var wantsNotificationsFromOnit: Bool { false }
    
    // MARK: - Functions
    
    // MARK: - Delegate Management
    
    func addDelegate(_ delegate: HighlightedTextDelegate) {
        delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate: HighlightedTextDelegate) {
        delegates.remove(delegate)
    }
    
    private func notifyDelegates(_ notification: (HighlightedTextDelegate) -> Void) {
        for case let delegate as HighlightedTextDelegate in delegates.allObjects {
            notification(delegate)
        }
    }
    
    func setCurrentSource(_ source: String?) {
        currentSource = source
    }
    
    func handleSelectionChange(for element: AXUIElement, selectedText: String? = nil) {
        guard HighlightedTextValidator.isValid(element: element) else { return }
        
        // Fix to work with PDF in Chrome
        // In PDF in chrome, we get two notifications at almost the exact same time.
        // First from AXGroup with the correct selectedText
        // Second from AXWebArea with nil selectedText. 
        // However, on Github, we get the opposite. 
        // First from AXWebArea with nil selectedText
        // Second from AXCell with the correct selectedText
        // So our original fix for the PDF in chrome broke Github. 
        // TIM: I'm setting this up so it only ignores when the new selectedText is nil. 
        // This may cause issues when deselected text, but since you can easily remove selected text in the interface, I think that's better than registering the text!
        // UPDATE: that change broke Cursor. We really just need to move away from Accessibility!
        if let lastHighlightingProcessedAt = lastHighlightingProcessedAt, Date().timeIntervalSince(lastHighlightingProcessedAt) < 0.002 {
            return
        }
        
        lastHighlightingProcessedAt = Date()
        selectionDebounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.processSelectionChange(for: element, selectedText: selectedText)
        }

        selectionDebounceWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + HighlightedTextConfig.textSelectionDebounceInterval, execute: workItem)
    }
    
    func processSelectionChange(for element: AXUIElement, selectedText: String? = nil) {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))


        if let selectedText = selectedText, HighlightedTextValidator.isValid(text: selectedText) {
            guard !PrivacyManager.shared.shouldBlockDataCollection() else {
                self.selectedText = nil
                self.selectedTextElement = nil
                return
            }

            // Commented out - now using mouse location fallback in QuickEditTriggerService
//            Task {
//                // We don't want to block the processing with highlighted bound detection: otherwise it makes it so the text is slow to appear on the panel.
//                // Leaving this in for now, but we need to find a different way to detect bounds without blocking the highlighted text callbacks.
//                _ = await HighlightedTextBoundsExtractor.shared.getBounds(for: element, selectedText: selectedText)
//                processSelectedText(selectedText, element: element)
//            }
            processSelectedText(selectedText, element: element)
        } else {
            // On every apps, when cursor position changed, we receive AXSelectedTextChanged notification with nil value.
            // This code is used to hide the QuickEdit hint for a real deselection
            let now = Date()
            let cursorPositionChangeRecently = now.timeIntervalSince(lastCursorPositionChangeTimestamp ?? .distantPast) < 0.5
            let isEditableField = element.role() == kAXTextFieldRole || element.role() == kAXTextAreaRole

            if !cursorPositionChangeRecently && !isEditableField {
                // Commented out - now using mouse location fallback in QuickEditTriggerService
                // HighlightedTextBoundsExtractor.shared.reset()
            } else if isEditableField {
                lastCursorPositionChangeTimestamp = Date()
            }
            // We must always process the nil selected text because the panel relies on it.
            processSelectedText(nil, element: nil)
        }
    }
    
    func processSelectedText(_ text: String?, element: AXUIElement? = nil) {
        guard Defaults[.autoContextFromHighlights],
              let selectedText = text,
              HighlightedTextValidator.isValid(text: selectedText) else {
            
            // Update the published selectedText property
            self.selectedText = nil
            self.selectedTextElement = nil
            
            // Notify delegates that text was deselected
            notifyDelegates {
                $0.highlightedTextManager(self, didChange: nil, application: currentSource)
            }
            return
        }
        
        guard !PrivacyManager.shared.shouldBlockDataCollection() else {
            self.selectedText = nil
            self.selectedTextElement = nil
            return
        }
        
        // Update the published selectedText property
        self.selectedText = selectedText
        self.selectedTextElement = element

        // Notify delegates about the text change
        notifyDelegates {
            $0.highlightedTextManager(self, didChange: selectedText, application: currentSource)
        }
    }
    
    func reset() {
        lastHighlightingProcessedAt = nil
        selectionDebounceWorkItem?.cancel()
        selectedText = nil
        selectedTextElement = nil
    }
}
