//
//  TypingChangeDelegate.swift
//  Onit
//
//  Created by Timothy Lenardo on 6/18/25.
//

import Foundation
import AppKit

// MARK: - Typing Change Info

struct TypingChangeInfo {
    let appBundleUrl: URL?
    let windowName: String?
    let pid: pid_t?
    let element: AXUIElement?
    let trackedWindow: TrackedWindow?
    let changeType: TypingChangeType
    let newValue: String?
    let selectedText: String?
    let bounds: CGRect?
    let precedingText: String?
    let followingText: String?
}

enum TypingChangeType {
    case valueChanged
    case selectionChanged
    case textElementFocused
}

// MARK: - Typing Change Delegate

final class TypingChangeDelegate: AccessibilityNotificationsDelegate {
    // MARK: - AccessibilityNotificationsDelegate - Typing Methods
    
    private var initialValue : String? = nil
    private var valueDebounceWorkItem: DispatchWorkItem?
    
    private let onValueChange: (AXUIElement?, String?) -> Void
    private let onTextFocused: (AXUIElement?) -> Void
    
    init(onValueChanged: @escaping (AXUIElement?, String?) -> Void, onTextFocused: @escaping (AXUIElement?) -> Void) {
        self.onValueChange = onValueChanged
        self.onTextFocused = onTextFocused
    }
    
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didChangeValue element: AXUIElement,
        newValue: String?,
        window: TrackedWindow?
    ) {
        // TODO handle this
        // If this is the first value change, store the initial value
        if initialValue == nil {
            initialValue = element.value()
        }

        // Check for special characters that should trigger immediate processing
        if let value = element.value() {
            let lastChar = value.last
            if lastChar == "." || lastChar == "!" || lastChar == "?" ||
                lastChar == "\n" || lastChar == "\r" || lastChar == "\t" {
                // Process immediately without debouncing
                onValueChange(element, newValue)
                initialValue = nil
                return
            }
        }
    
        // Otherwise, listen for 1s stops in the typing.
        valueDebounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.onValueChange(element, newValue)
            self.initialValue = nil  // Reset the initial value after processing
        }

        valueDebounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + TypingChangeDelegate.Config.typingDebounceInterval, execute: workItem)
    }
    
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didFocusTextElement element: AXUIElement,
        window: TrackedWindow?
    ) {
        onTextFocused(element)
    }
    
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didChangeSelection element: AXUIElement,
        selectedText: String?,
        bounds: CGRect?,
        window: TrackedWindow?
    ) {
        // For now, we don't need to handle selection changes for typeahead learning
        // But this method is required by the protocol
    }

    // MARK: - AccessibilityNotificationsDelegate - Required Methods (Empty Implementations)
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeWindowTitle window: TrackedWindow) {}
}

extension TypingChangeDelegate {
    struct Config {
        static let typingDebounceInterval: TimeInterval = 1.0 // 1s
    }
}
