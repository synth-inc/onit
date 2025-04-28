//
//  HighlightedTextPoller.swift
//  Onit
//
//  Created by Kévin Naudin on 28/04/2025.
//

import Cocoa
import ApplicationServices

class HighlightedTextPoller {
    private let queue = DispatchQueue(label: "inc.synth.onit.HighlightedTextPoller", qos: .userInteractive)
    private let searchSemaphore = DispatchSemaphore(value: 1)
    
    private var timer: DispatchSourceTimer?
    private var selectionChangedHandler: ((String) -> Void)?
    private var deselectionHandler: (() -> Void)?
    private var lastSelectedText: String?
    private var foundSelectedText = false
    
    
    /// TODO: KNA
    /// - Reduce the CPU (Stop searching when selected text is found)
    /// - Limit with max depth
    /// - Replace the old logic by the new one
    
    
    func startPolling(
        observedElement: AXUIElement,
        interval: TimeInterval = 0.5,
        selectionChangedHandler: @escaping (String) -> Void,
        deselectionHandler: @escaping () -> Void
    ) {
        stopPolling()
        
        self.selectionChangedHandler = selectionChangedHandler
        self.deselectionHandler = deselectionHandler
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            if self.searchSemaphore.wait(timeout: .now()) != .success {
                return
            }
            
            self.foundSelectedText = false
            self.checkSelection(for: observedElement)
            
            if !self.foundSelectedText && self.lastSelectedText != nil {
                self.lastSelectedText = nil
                self.deselectionHandler?()
            }
            
            self.searchSemaphore.signal()
        }
        
        self.timer = timer
        timer.resume()
    }
    
    func stopPolling() {
        timer?.cancel()
        timer = nil
    }
    
    private func checkSelection(for observedElement: AXUIElement) {
        var selectedTextValue: AnyObject?
        let error = AXUIElementCopyAttributeValue(observedElement, kAXSelectedTextAttribute as CFString, &selectedTextValue)
        
        if error == .success, let selectedText = selectedTextValue as? String, !selectedText.isEmpty {
            processSelectedText(selectedText, in: observedElement)
            return
        }
        
        scanElementHierarchyForSelectedText(element: observedElement)
    }
    
    private func scanElementHierarchyForSelectedText(element: AXUIElement) {
        var documentValue: AnyObject?
        let documentError = AXUIElementCopyAttributeValue(element, kAXDocumentAttribute as CFString, &documentValue)
        
        if documentError == .success, let document = documentValue {
            var textValue: AnyObject?
            let textError = AXUIElementCopyAttributeValue(document as! AXUIElement, kAXSelectedTextAttribute as CFString, &textValue)
            
            if textError == .success, let selectedText = textValue as? String, !selectedText.isEmpty {
                processSelectedText(selectedText, in: document as! AXUIElement)
                return
            }
        }
        
        findSelectedTextInChildren(of: element)
    }
    
    private func findSelectedTextInChildren(of element: AXUIElement, depth: Int = 0) {
        guard let children = element.children() else {
            return
        }
        
        for child in children {
            var selectedTextValue: AnyObject?
            let textError = AXUIElementCopyAttributeValue(child, kAXSelectedTextAttribute as CFString, &selectedTextValue)
            
            if textError == .success, 
               let selectedText = selectedTextValue as? String,
               !selectedText.isEmpty {
//                log.error("depth: \(depth)")
                processSelectedText(selectedText, in: child)
                return
            }
            
            findSelectedTextInChildren(of: child, depth: depth + 1)
        }
    }
    
    private func processSelectedText(_ selectedText: String, in element: AXUIElement) {
        guard AccessibilityTextSelectionFilter.filter(element: element) == false else { return }
        
        foundSelectedText = true
        
        if selectedText != lastSelectedText {
            lastSelectedText = selectedText
            selectionChangedHandler?(selectedText)
        }
    }
    
    deinit {
        stopPolling()
    }
}
