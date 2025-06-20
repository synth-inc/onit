//
//  QuickEditManager.swift
//  Onit
//
//  Created by Kévin Naudin on 06/10/2025.
//

import Foundation
import AppKit
import Combine
import Defaults

@MainActor
class QuickEditManager: ObservableObject, CaretPositionDelegate {
    
    // MARK: - Singleton instance
    
    static let shared = QuickEditManager()
    
    // MARK: - Window Configuration
    
    static let estimatedWindowSize = CGSize(width: 360, height: 120)
    static let minimumSpacing: CGFloat = 10
    
    // MARK: - Properties
    
    private let windowController = QuickEditWindowController()
    private let hintWindowController = QuickEditHintWindowController()
    private let caretPositionManager = CaretPositionManager.shared
    private let accessibilityManager = AccessibilityNotificationsManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentHintPosition: CGPoint?
    
    // MARK: - Private initializer
    
    private init() {
        setupMonitoring()
    }
    
    // MARK: - Functions
    
    func show() {
        if let hintPosition = currentHintPosition {
            let correctPosition = calculateWindowPosition(for: hintPosition)
            
            windowController.show(at: correctPosition)
        }
    }
    
    func hide() {
        windowController.hide()
    }
    
    func showHint(at position: CGPoint, appName: String?) {
        currentHintPosition = position
        hintWindowController.show(at: position, appName: appName)
    }
    
    func hideHint() {
        currentHintPosition = nil
        hintWindowController.hide()
    }
    
    // MARK: - Private Functions
    
    // MARK: Setup
    
    private func setupMonitoring() {
        setupTextSelectionMonitoring()
        setupCaretPositionMonitoring()
    }
    
    private func setupTextSelectionMonitoring() {
        accessibilityManager.$screenResult
            .map(\.userInteraction.selectedText)
            .removeDuplicates()
            .sink { [weak self] selectedText in
                self?.handleTextSelectionChange(selectedText)
            }
            .store(in: &cancellables)
    }
    
    private func setupCaretPositionMonitoring() {
        caretPositionManager.addDelegate(self)
    }
    
    // MARK: Text Selection Handling
    
    private func handleTextSelectionChange(_ selectedText: String?) {
		guard Defaults[.quickEditConfig].isEnabled else { return }
        
        log.error("handleTextSelectionChange: \(selectedText ?? "nil")")
        
        if hasTextSelection(selectedText) {
            if let (position, appName) = getTextSelectionPosition(selectedText) {
                if shouldShowQuickEdit(for: appName) {
                    log.error("Showing hint for text selection at: \(position)")
                    showHint(at: position, appName: appName)
                } else {
                    log.error("QuickEdit disabled/paused for \(appName)")
                    hideHint()
                }
            } else {
                log.error("No position found for text selection")
                hideHint()
            }
        }
    }
    
    private func hasTextSelection(_ selectedText: String?) -> Bool {
        guard let selectedText = selectedText,
              HighlightedTextValidator.isValid(text: selectedText) else {
            return false
        }
        
        return true
    }
    
    private func getTextSelectionPosition(_ selectedText: String?) -> (CGPoint, String)? {
        guard let selectedText = selectedText else {
            return nil
        }
        
        if let lastResult = HighlightedTextBoundsExtractor.shared.getLastResult(),
           lastResult.highlightedText == selectedText {
            let screenFrame = convertAccessibilityToMacOSCoordinates(lastResult.highlightedTextFrame)
            log.error("Bounds found for selected text: \(lastResult.highlightedTextFrame) in MacOS coordinates: \(screenFrame)")
            return (CGPoint(x: screenFrame.origin.x, y: screenFrame.origin.y), lastResult.appName)
        }
        
        log.error("No bounds found for selected text")
        return nil
    }
    
    // MARK: Caret Position Handling
    
    private func handleCaretPositionChange(appName: String?) {
		guard Defaults[.quickEditConfig].isEnabled else { return }

        if let appName = appName, !shouldShowQuickEdit(for: appName) {
            log.error("QuickEdit disabled/paused for \(appName)")
            hideHint()
            return
        }
        
        if hasCaretPosition() {
            if let position = getCaretPosition() {
                showHint(at: position, appName: appName)
            } else {
                hideHint()
            }
        } else {
            hideHint()
        }
    }
    
    private func hasCaretPosition() -> Bool {
        let hasCaretPosition = caretPositionManager.isCaretVisible
        
        return hasCaretPosition
    }
    
    private func getCaretPosition() -> CGPoint? {
        guard let caretPosition = caretPositionManager.currentCaretPosition else {
            return nil
        }
        
        return CGPoint(x: caretPosition.origin.x, y: caretPosition.origin.y)
    }
    
    // MARK: Utilities
    
    private func isQuickEditDisabled(for appName: String?) -> Bool {
        guard let appName = appName else { return false }

        let config = Defaults[.quickEditConfig]

        return config.excludedApps.contains(appName)
    }
    
    private func isQuickEditPaused(for appName: String?) -> Bool {
        guard let appName = appName else { return false }

        let config = Defaults[.quickEditConfig]

        guard let pauseEndDate = config.pausedApps[appName] else {
            return false
        }
        
        if Date() > pauseEndDate {
            Defaults[.quickEditConfig].pausedApps.removeValue(forKey: appName)
            return false
        }
        
        return true
    }
    
    private func shouldShowQuickEdit(for appName: String?) -> Bool {
        guard let appName = appName else { return true }
		
        return !isQuickEditDisabled(for: appName) && !isQuickEditPaused(for: appName)
    }
    
    private func convertAccessibilityToMacOSCoordinates(_ rect: CGRect) -> CGRect {
        guard let mainScreen = NSScreen.primary else {
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
    
    private func calculateWindowPosition(for hintPosition: CGPoint) -> CGPoint {
        guard let hintScreen = hintWindowController.window?.screen ?? NSScreen.main else {
            return hintPosition
        }
        
        let hintSize = QuickEditHintWindowController.hintSize
        let actualHintPosition = CGPoint(
            x: hintPosition.x + QuickEditHintWindowController.hintOffset.x,
            y: hintPosition.y + QuickEditHintWindowController.hintOffset.y
        )
        
        let windowSize = Self.estimatedWindowSize
        let screenFrame = hintScreen.visibleFrame
        let hintTopY = actualHintPosition.y + hintSize.height
        let spaceAbove = screenFrame.maxY - hintTopY
        
        let windowPosition: CGPoint
        if spaceAbove >= windowSize.height {
            windowPosition = CGPoint(
                x: hintPosition.x - 10,
                y: hintTopY
            )
        } else {
            windowPosition = CGPoint(
                x: hintPosition.x - 10,
                y: actualHintPosition.y - windowSize.height
            )
        }
        
        return windowPosition
    }
}

// MARK: - CaretPositionDelegate

extension QuickEditManager {
    func caretPositionDidChange(_ position: CGRect, in application: String, element: AXUIElement) {
        handleCaretPositionChange(appName: application)
    }
    
    func caretPositionDidUpdate(_ position: CGRect, in application: String, element: AXUIElement) {
        handleCaretPositionChange(appName: application)
    }
    
    func caretDidDisappear() {
        if !hasTextSelection(accessibilityManager.screenResult.userInteraction.selectedText) {
            hideHint()
        }
    }
}
