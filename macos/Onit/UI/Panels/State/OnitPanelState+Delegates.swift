//
//  OnitPanelState+NSWindowDelegate.swift
//  Onit
//
//  Created by Kévin Naudin on 16/05/2025.
//

import AppKit
import Defaults

extension OnitPanelState: NSWindowDelegate {
    
    func windowDidBecomeKey(_ notification: Notification) {
        notifyDelegates { $0.panelBecomeKey(state: self) }
    }

    func windowDidResignKey(_ notification: Notification) {
        notifyDelegates { $0.panelResignKey(state: self) }
    }

    func windowWillMiniaturize(_ notification: Notification) {
        if !panelMiniaturized {
            panelMiniaturized = true
        }
    }
    
    func windowDidDeminiaturize(_ notification: Notification) {
        if panelMiniaturized {
            panelMiniaturized = false
        }
    }
}

extension OnitPanelState: HighlightedTextDelegate {
    func highlightedTextDidChange(selectedText: String?, application: String?) {
        if let selectedText = selectedText {
            let input = Input(selectedText: selectedText, application: application ?? "")

            if Defaults[.autoAddHighlightedTextToContext] {
                pendingInput = input
            } else {
                trackedPendingInput = input
            }
        } else {
            // Text was deselected
            pendingInput = nil
            trackedPendingInput = nil
        }
    }
}

extension OnitPanelState: FocusedTextFieldDelegate {
    func focusedTextFieldDidChange(_ textField: AXUIElement?) {
        if let textField = textField {
            var value: AnyObject?
            let result = AXUIElementCopyAttributeValue(textField, kAXValueAttribute as CFString, &value)
            if result == .success, let stringValue = value as? String {
                print("FocusedTextFieldDelegate - Focused text field value (first 100 chars): \(stringValue.prefix(100))")
            } else {
                print("FocusedTextFieldDelegate - Focused text field value could not be retrieved")
            }
        } else {
            print("FocusedTextFieldDelegate - Focused text field is nil")
        }
    }
}
