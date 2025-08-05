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
    
    // MARK: - Published Properties
    @Published private(set) var currentAppName: String?
    @Published private(set) var isEditableElement: Bool = false
    
    // MARK: - Window Configuration
    
    static let estimatedWindowSize = CGSize(width: 360, height: 120)
    static let minimumSpacing: CGFloat = 10
    
    // MARK: - Properties
    
    private let windowController = QuickEditWindowController()
    private let hintWindowController = QuickEditHintWindowController()
    private let caretPositionManager = CaretPositionManager.shared
    private let highlightedTextManager = HighlightedTextManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentHintPosition: CGPoint?
    private var currentHintHeight: CGFloat?
    private var lastElement: AXUIElement?
    
    // MARK: - Private initializer
    
    private init() {
        setupMonitoring()
    }
    
    // MARK: - Functions
    
    func show() {
        if let hintPosition = currentHintPosition {
            let hintOffset = QuickEditHintWindowController.hintOffset
            let hintPositionWithOffset = CGPoint(
                x: hintPosition.x + hintOffset.x,
                y: hintPosition.y + hintOffset.y
            )
            
            windowController.show(at: hintPositionWithOffset, hintHeight: currentHintHeight)
        } else {
            log.error("Can't find currentHintPosition")
        }
    }
    
    func hide() {
        windowController.hide()
    }
    
    func showHint(at position: CGPoint, height: CGFloat? = nil) {
		let realHeight = height ?? QuickEditHintWindowController.hintSize.height
        let finalHeight = max(realHeight, QuickEditHintWindowController.hintSize.height)

		currentHintPosition = position
        currentHintHeight = finalHeight
        hintWindowController.show(at: position, height: finalHeight)
    }
    
    func hideHint() {
        currentHintPosition = nil
        currentHintHeight = nil
		isEditableElement = false
        hintWindowController.hide()
        hideMenu()
    }
    
    func showMenu() {
        hintWindowController.showMenu()
    }
    
    func hideMenu() {
        hintWindowController.hideMenu()
    }
    
    func activateLastApp() {
        guard let element = lastElement, let pid = element.pid() else { return }
        
        if let runningApp = NSRunningApplication(processIdentifier: pid) {
            runningApp.activate()
        }
    }
    
    // MARK: - Private Functions
    
    // MARK: Setup
    
    private func setupMonitoring() {
        setupTextSelectionMonitoring()
        setupCaretPositionMonitoring()
    }
    
    private func setupTextSelectionMonitoring() {
        // Monitor the selectedText property from HighlightedTextManager
        highlightedTextManager.$selectedText
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
            if let (frame, highlightedResult) = getTextSelectionPosition(selectedText) {
                if shouldShowQuickEdit(for: highlightedResult.appName) {
                    log.error("Showing hint for text selection at: \(frame)")
                    isEditableElement = highlightedResult.elementRole == kAXTextFieldRole || highlightedResult.elementRole == kAXTextAreaRole
                    currentAppName = highlightedResult.appName
                    lastElement = highlightedResult.element
                    showHint(at: frame.origin, height: frame.height)
                    
                    #if DEBUG
                    if Defaults[.quickEditConfig].shouldCaptureTrainingData {
                        Task {
                            await HighlightedTextBoundTrainingDataManager.shared.captureTrainingData(
                                selectedText: highlightedResult.highlightedText,
                                boundingBox: frame,
                                appName: highlightedResult.appName,
                                element: highlightedResult.element
                            )
                        }
                    }
                    #endif
                } else {
                    log.error("QuickEdit disabled/paused for \(highlightedResult.appName)")
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
    
    private func getTextSelectionPosition(_ selectedText: String?) -> (CGRect, HighlightedTextBoundsResult)? {
        guard let selectedText = selectedText else {
            return nil
        }
        
        if let lastResult = HighlightedTextBoundsExtractor.shared.getLastResult(),
           lastResult.highlightedText == selectedText {
            let convertedFrame = convertAccessibilityToMacOSCoordinates(lastResult.highlightedTextFrame)
            log.error("Bounds found for selected text: \(lastResult.highlightedTextFrame) in MacOS coordinates: \(convertedFrame)")
            return (convertedFrame, lastResult)
        }
        
        log.error("No bounds found for selected text")
        return nil
    }
    
    // MARK: Caret Position Handling
    
    private func handleCaretPositionChange(element: AXUIElement, appName: String?) {
		guard Defaults[.quickEditConfig].isEnabled else { return }

        if let appName = appName, !shouldShowQuickEdit(for: appName) {
            log.error("QuickEdit disabled/paused for \(appName)")
            hideHint()
            return
        }
        
        if hasCaretPosition() {
            if let position = getCaretPosition() {
                isEditableElement = true
                currentAppName = appName
                lastElement = element
                showHint(at: position)
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
}

// MARK: - CaretPositionDelegate

extension QuickEditManager {
    func caretPositionDidChange(_ position: CGRect, in application: String, element: AXUIElement) {
        handleCaretPositionChange(element: element, appName: application)
    }
    
    func caretPositionDidUpdate(_ position: CGRect, in application: String, element: AXUIElement) {
        handleCaretPositionChange(element: element, appName: application)
    }
    
    func caretDidDisappear() {
        if !hasTextSelection(highlightedTextManager.selectedText) {
            hideHint()
        }
    }
}
