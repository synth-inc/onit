//
//  HighlightedTextPoller.swift
//  Onit
//
//  Created by Kévin Naudin on 28/04/2025.
//

import Cocoa
import Defaults
import ApplicationServices

class HighlightedTextPoller {
    static let appNames: [String] = [
        "Notes",
        "iTerm2"
    ]
    
    private let queue = DispatchQueue(label: "inc.synth.onit.HighlightedTextPoller", qos: .userInteractive)
    
    private var timerByPID: [pid_t: DispatchSourceTimer] = [:]
    private var selectionChangedHandler: ((String?, AXUIElement?) -> Void)?
    private var lastSelectedText: String?
    private var foundSelectedText = false
    private let maxSearchDepth = 100
    
    func startPolling(
        pid: pid_t,
        interval: TimeInterval = 0.5,
        selectionChangedHandler: @escaping (String?, AXUIElement?) -> Void
    ) {
        stopPolling(pid: pid)
        
        guard let appName = pid.getAppName(), Self.appNames.contains(appName) else {
            return
        }
        
        self.selectionChangedHandler = selectionChangedHandler
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            guard Defaults[.autoContextFromHighlights],
                  let self = self,
                  let focusedWindow = pid.getFocusedWindow() else {
                return
            }
            
            self.foundSelectedText = false
            
            guard !self.highlightedTextFound(for: focusedWindow) else {
                return
            }
            
            scanElementHierarchyForSelectedText(focusedWindow: focusedWindow)
            
            if !self.foundSelectedText && self.lastSelectedText != nil {
                self.lastSelectedText = nil
                self.selectionChangedHandler?(nil, nil)
            }
        }
        
        timerByPID[pid] = timer
        timer.resume()
    }
    
    func stopPolling(pid: pid_t) {
        timerByPID[pid]?.cancel()
        timerByPID[pid] = nil
    }
    
    private func highlightedTextFound(for observedElement: AXUIElement) -> Bool {
        if let selectedText = observedElement.selectedText() {
            guard AccessibilityTextSelectionFilter.filter(element: observedElement) == false else {
                return false
            }
            
            processSelectedText(selectedText, in: observedElement)
            return true
        }
        
        return false
    }
    
    private func scanElementHierarchyForSelectedText(focusedWindow: AXUIElement) {
        var documentValue: AnyObject?
        let documentError = AXUIElementCopyAttributeValue(focusedWindow, kAXDocumentAttribute as CFString, &documentValue)
        
        if documentError == .success, let document = documentValue {
            guard !highlightedTextFound(for: document as! AXUIElement) else {
                return
            }
        }
        
        _ = highlightedTextFound(in: focusedWindow, element: focusedWindow)
    }
    
    private func highlightedTextFound(in focusedWindow: AXUIElement, element: AXUIElement, depth: Int = 0) -> Bool {
        guard depth < maxSearchDepth else {
            return false
        }
        
        guard let children = element.children() else {
            return false
        }
        
        for child in children {
            guard !highlightedTextFound(for: child) else {
                return true
            }
            
            guard !highlightedTextFound(in: focusedWindow, element: child, depth: depth + 1) else {
                return true
            }
        }
        
        return false
    }
    
    private func processSelectedText(_ selectedText: String, in element: AXUIElement) {
        foundSelectedText = true
        
        if selectedText != lastSelectedText {
            lastSelectedText = selectedText
            selectionChangedHandler?(selectedText, element)
        }
    }
    
    deinit {
        for pid in timerByPID.keys {
            stopPolling(pid: pid)
        }
    }
}
