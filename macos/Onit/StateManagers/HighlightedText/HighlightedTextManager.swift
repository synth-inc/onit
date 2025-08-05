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
    
    // MARK: - Private initializer
    
    private init() {
        AccessibilityNotificationsManager.shared.addDelegate(self)
    }
    
    // MARK: - AccessibilityNotificationsDelegate
    
    var wantsNotificationsFromIgnoredProcesses: Bool { false }
    var wantsNotificationsFromOnit: Bool { false }
    
    // MARK: - Functions
    
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
