//
//  QuickEditManager.swift
//  Onit
//
//  Created by Kévin Naudin on 06/10/2025.
//

import Foundation
import AppKit
import Combine

@MainActor
class QuickEditManager: ObservableObject, CaretPositionDelegate {
    
    // MARK: - Singleton instance
    
    static let shared = QuickEditManager()
    
    // MARK: - Properties
    
    private let windowController = QuickEditWindowController()
    private let hintWindowController = QuickEditHintWindowController()
    private let caretPositionManager = CaretPositionManager.shared
    private let accessibilityManager = AccessibilityNotificationsManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Private initializer
    
    private init() {
        setupMonitoring()
    }
    
    // MARK: - Functions
    
    func show() {
        windowController.show()
    }
    
    func hide() {
        windowController.hide()
    }
    
    func showHint(at position: CGPoint) {
        hintWindowController.show(at: position)
    }
    
    func hideHint() {
        hintWindowController.hide()
    }
    
    // MARK: - Private functions
    
    private func setupMonitoring() {
        caretPositionManager.addDelegate(self)
        
        accessibilityManager.$screenResult
            .map(\.userInteraction.selectedText)
            .removeDuplicates()
            .sink { [weak self] selectedText in
                log.error("")
                self?.handleTextSelectionChange(selectedText)
            }
            .store(in: &cancellables)
    }
    
    private func handleTextSelectionChange(_ selectedText: String?) {
        checkForTextSelection()
    }
    
    private func checkForTextSelection() {
        if hasTextSelection() || hasCaretPosition() {
            if let position = getTextSelectionPosition() {
                showHint(at: position)
            } else {
                hideHint()
            }
        } else {
            hideHint()
        }
    }
    
    private func hasTextSelection() -> Bool {
        return accessibilityManager.screenResult.userInteraction.selectedText != nil &&
               !accessibilityManager.screenResult.userInteraction.selectedText!.isEmpty
    }
    
    private func hasCaretPosition() -> Bool {
        return caretPositionManager.isCaretVisible
    }
    
    private func getTextSelectionPosition() -> CGPoint? {
        if hasTextSelection(),
           let selectedText = accessibilityManager.screenResult.userInteraction.selectedText,
           let lastResult = HighlightedTextBoundsExtractor.shared.getLastResult(),
		   lastResult.highlightedText == selectedText {
            let screenFrame = convertAccessibilityToMacOSCoordinates(lastResult.highlightedTextFrame)
            
            return CGPoint(x: screenFrame.origin.x, y: screenFrame.origin.y)
        }
        
        if let caretPosition = caretPositionManager.currentCaretPosition {
            return CGPoint(x: caretPosition.origin.x, y: caretPosition.origin.y)
        }
        
        return nil
    }
    
    private func convertAccessibilityToMacOSCoordinates(_ rect: CGRect) -> CGRect {
        guard let mainScreen = NSScreen.main else {
            return rect
        }
        
        let screenHeight = mainScreen.frame.height
        let convertedY = screenHeight - rect.origin.y - rect.height
        
        return CGRect(
            x: rect.origin.x,
            y: convertedY,
            width: rect.width,
            height: rect.height
        )
    }
}

// MARK: - CaretPositionDelegate

extension QuickEditManager {
    func caretPositionDidChange(_ position: CGRect, in application: String, element: AXUIElement) {
        checkForTextSelection()
    }
    
    func caretPositionDidUpdate(_ position: CGRect, in application: String, element: AXUIElement) {
        if let hintPosition = getTextSelectionPosition() {
            showHint(at: hintPosition)
        }
    }
    
    func caretDidDisappear() {
        if !hasTextSelection() {
            hideHint()
        }
    }
} 
