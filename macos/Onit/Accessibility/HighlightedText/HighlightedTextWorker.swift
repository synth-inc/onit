//
//  HighlightedTextWorker.swift
//  Onit
//
//  Created by Kévin Naudin on 30/04/2025.
//

import ApplicationServices
import Defaults
import Foundation

final class HighlightedTextWorker {
    private let pid: pid_t
    private let interval: TimeInterval
    private let selectionChangedHandler: @Sendable (String?, CGRect?) -> Void
    private let queue = DispatchQueue(label: "inc.synth.onit.HighlightedTextWorker", qos: .userInteractive)
    
    private var timer: DispatchSourceTimer?
    private var lastSelectedText: String?
    private var foundSelectedText = false
    private let maxSearchDepth = 100

    init(pid: pid_t,
         interval: TimeInterval,
         selectionChangedHandler: @escaping @Sendable (String?, CGRect?) -> Void) {
        self.pid = pid
        self.interval = interval
        self.selectionChangedHandler = selectionChangedHandler
    }

    func start() {
        let handler = selectionChangedHandler
        let timer = DispatchSource.makeTimerSource(queue: queue)
        
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            guard let self = self,
                  Defaults[.autoContextFromHighlights],
                  let focusedWindow = self.pid.getFocusedWindow() else {
                return
            }

            self.foundSelectedText = false

            guard !self.highlightedTextFound(for: focusedWindow) else {
                return
            }

            self.scanElementHierarchyForSelectedText(focusedWindow: focusedWindow)

            if !self.foundSelectedText && self.lastSelectedText != nil {
                self.lastSelectedText = nil
                Task { @MainActor in
                    handler(nil, nil)
                }
            }
        }
        timer.resume()
        
        self.timer = timer
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func highlightedTextFound(for element: AXUIElement) -> Bool {
        if let selectedText = element.selectedText(),
           HighlightedTextValidator.isValid(element: element) {
            
            processSelectedText(selectedText, in: element)
            
            return true
        }
        
        return false
    }

    private func scanElementHierarchyForSelectedText(focusedWindow: AXUIElement) {
        var documentValue: AnyObject?
        let error = AXUIElementCopyAttributeValue(focusedWindow, kAXDocumentAttribute as CFString, &documentValue)
        
        if error == .success, let document = documentValue {
            if highlightedTextFound(for: document as! AXUIElement) {
                return
            }
        }

        _ = highlightedTextFound(in: focusedWindow, element: focusedWindow)
    }

    private func highlightedTextFound(in focusedWindow: AXUIElement, element: AXUIElement, depth: Int = 0) -> Bool {
        guard depth < maxSearchDepth else { return false }
        guard let children = element.children() else { return false }

        for child in children {
            if highlightedTextFound(for: child) {
                return true
            }
            if highlightedTextFound(in: focusedWindow, element: child, depth: depth + 1) {
                return true
            }
        }

        return false
    }

    private func processSelectedText(_ selectedText: String, in element: AXUIElement) {
        foundSelectedText = true
        if selectedText != lastSelectedText {
            lastSelectedText = selectedText

            let handler = self.selectionChangedHandler
            let elementBounds = element.selectedTextBound()
            
            Task { @MainActor in
                handler(selectedText, elementBounds)
            }
        }
    }
}
