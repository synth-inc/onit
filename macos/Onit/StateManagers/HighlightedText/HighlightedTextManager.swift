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
    private var lastCaretPositionChangeTimestamp: Date?
    
    // Published property for selected text that QuickEditManager can observe
    @Published var selectedText: String?
    
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
    
    func handleSelectionChange(for element: AXUIElement) {
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

        DispatchQueue.main.asyncAfter(deadline: .now() + HighlightedTextConfig.textSelectionDebounceInterval, execute: workItem)
    }
    
    func processSelectionChange(for element: AXUIElement) {
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
    }
    
    func processSelectedText(_ text: String?) {
        guard Defaults[.autoContextFromHighlights],
              let selectedText = text,
              HighlightedTextValidator.isValid(text: selectedText) else {
            
            // Update the published selectedText property
            self.selectedText = nil
            
            // Notify delegates that text was deselected
            notifyDelegates {
                $0.highlightedTextManager(self, didChange: nil, application: currentSource)
            }
            return
        }
        
        // Update the published selectedText property
        self.selectedText = selectedText

        // Notify delegates about the text change
        notifyDelegates {
            $0.highlightedTextManager(self, didChange: selectedText, application: currentSource)
        }
    }
    
    func handleCaretPositionChange(for element: AXUIElement) {
        guard element.supportsCaretTracking() else { return }
        
        selectionDebounceWorkItem?.cancel()
        selectionDebounceWorkItem = nil
        processSelectedText(nil)
        lastCaretPositionChangeTimestamp = Date()
        CaretPositionManager.shared.updateCaretPosition(for: element)
    }
    
    func reset() {
        lastHighlightingProcessedAt = nil
        selectionDebounceWorkItem?.cancel()
        selectedText = nil
    }
}
