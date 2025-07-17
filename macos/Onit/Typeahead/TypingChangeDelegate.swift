//
//  TypingChangeDelegate.swift
//  Onit
//
//  Created by Timothy Lenardo on 6/18/25.
//

import Foundation
import AppKit
import Defaults

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

// MARK: - Text Change Types

enum TextChangeType: String {
    case addition = "addition"
    case deletion = "deletion"
    case modification = "modification"
}

struct TextChange {
    let type: TextChangeType
    let addedText: String?
    let deletedText: String?
    let insertionIndex: Int? // Position where the change occurred
    let textPrefixRange: NSRange? // Range of text before the edit
    let textSuffixRange: NSRange? // Range of text after the edit
    
    // This is for the main ones, to create the test cases.
    var initialText: String?
    var endText: String?
    var trigger: String?
}

// MARK: - Typing Change Delegate

final class TypingChangeDelegate: AccessibilityNotificationsDelegate {
    // MARK: - AccessibilityNotificationsDelegate - Typing Methods
    
    private var focusedTextFieldId: UInt? = nil
    private var focusedTextElement: AXUIElement? = nil

    private var initialValue : String? = nil
    private var initialInsertionIndex: Int? = nil
    
    private var mostRecentValue : String? = nil
    private var mostRecentInsertionIndex: Int? = nil
    
    private var valueDebounceWorkItem: DispatchWorkItem?
    
    // MARK: - Rate Limiting for Excessive Notifications
    
    private var elementNotificationCounts: [UInt: (count: Int, firstNotificationTime: Date)] = [:]
    private var elementCharacterCounts: [UInt: (characters: Int, firstNotificationTime: Date)] = [:]
    private var ignoredElements: Set<UInt> = []
    
    private let onPhraseEntered: (AXUIElement?, String?, TextChange?) -> Void
    private let onTextFocused: (AXUIElement?) -> Void
    
    init(onPhraseEntered: @escaping (AXUIElement?, String?, TextChange?) -> Void, onTextFocused: @escaping (AXUIElement?) -> Void) {
        self.onPhraseEntered = onPhraseEntered
        self.onTextFocused = onTextFocused
    }
    
    // MARK: - Shared Phrase Completion Logic
    
    private func finishPhrase(element: AXUIElement?, endValue: String?, trigger: String) {
        let fullTextChange = calculateTextChangeFast(from: initialValue, to: endValue)
        if var unwrappedFullTextChange = fullTextChange {
            unwrappedFullTextChange.trigger = trigger
            unwrappedFullTextChange.initialText = initialValue
            unwrappedFullTextChange.endText = endValue
            
            onPhraseEntered(element, endValue, unwrappedFullTextChange)
        } else {
            print("typeaheadPhraseDebug - no change detected for trigger: \(trigger)")
        }
    }
    
    // MARK: - Rate Limiting Logic
    
    private func shouldIgnoreElement(_ elementId: UInt, addedText: String?) -> Bool {
        // If already ignored, continue ignoring
        if ignoredElements.contains(elementId) {
            return true
        }

        let now = Date()
        // Check if this might be a paste operation
        if let addedText = addedText, !addedText.isEmpty {
            let pasteboard = NSPasteboard.general
            if let pasteboardString = pasteboard.string(forType: .string),
               pasteboardString.contains(addedText) {
                // This appears to be a paste operation, don't ignore
                print("typeaheadDebug - paste operation, not ignoring")
                return false
            }
        }
        
        // Get or create tracking info for this element
        if let existing = elementCharacterCounts[elementId] {
            let timeSinceFirst = now.timeIntervalSince(existing.firstNotificationTime)
            let characterCount = existing.characters + (addedText?.count ?? 0)
            
            // Check if we've received too many characters in a short time period
            if timeSinceFirst <= TypingChangeDelegate.Config.rateLimitWindow &&
               characterCount >= TypingChangeDelegate.Config.maxCharactersPerWindow {
                
                print("typeaheadDebug - Element \(elementId) generating excessive characters (\(characterCount) in \(timeSinceFirst)s), ignoring future notifications")
                ignoredElements.insert(elementId)
                elementCharacterCounts.removeValue(forKey: elementId)
                return true
            }
            
            // Update character count
            elementCharacterCounts[elementId] = (characters: characterCount, firstNotificationTime: existing.firstNotificationTime)
        } else {
            // First notification from this element
            elementCharacterCounts[elementId] = (characters: addedText?.count ?? 0, firstNotificationTime: now)
        }
        
        return false
    }
    
    private func cleanupOldElementTracking() {
        let now = Date()
        let cutoffTime = now.addingTimeInterval(-TypingChangeDelegate.Config.rateLimitWindow)
        
        elementCharacterCounts = elementCharacterCounts.filter { _, value in
            value.firstNotificationTime > cutoffTime
        }
    }
    
    // LLM - NOTE
    // If we read the elements value() field there's a chance it's changed since the initial read.
    // To make sure we get all of the updates, we need to ONLY process the newValue that is passed through the function.
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didChangeValue element: AXUIElement,
        newValue: String?,
        window: TrackedWindow?
    ) {
        let elementId = CFHash(element)
        if ignoredElements.contains(elementId) {
            print("typeaheadDebug - element \(element.description()) is ignored, skipping")
            return
        }
        
        // This is an edge case where value changed notifications start coming from a textfield that we haven't
        // received a 'didFocusTextElement'        
        if let currentId = focusedTextFieldId, currentId != elementId, initialValue != nil {
//            print("typeaheadDebug - ignoring from non-focused element \(element.description())")
//            return
            finishPhrase(element: focusedTextElement, endValue: mostRecentValue, trigger: "elementChange")
            initialValue = nil
            initialInsertionIndex = nil
            mostRecentValue = nil
        }
        
        // Update current element tracking
        focusedTextFieldId = elementId
        focusedTextElement = element
        
        // If this is the first value change, store the initial value
        if initialValue == nil {
            print("typeaheadDebug - resetting initial value")
            initialValue = newValue
            mostRecentValue = newValue
        }
        
        // Fast difference calculation for every character change
        let textChange = calculateTextChangeFast(from: mostRecentValue, to: newValue)
        if let change = textChange {

            // TIM TODO: resume this project and ignore apps that are spamming.
//            if shouldIgnoreElement(elementId, addedText: change.addedText) {
//                return
//            }
            
            print("typeaheadDebug - Change: \(change.type.rawValue) at position \(change.insertionIndex ?? -1), textAdded: \(change.addedText ?? "") textRemoved: \(change.deletedText ?? "")")
            if initialInsertionIndex == nil {
                initialInsertionIndex = change.insertionIndex
                mostRecentInsertionIndex = change.insertionIndex
            }

            // We only look at the last character when text is added.
            let lastChar = change.addedText?.last?.description ?? ""
            if lastChar == "." || lastChar == "!" || lastChar == "?" ||
                lastChar == "\n" || lastChar == "\r" || lastChar == "\t" {
                // Process immediately without debouncing
                finishPhrase(element: element, endValue: newValue, trigger: "enterCharacter")
                initialInsertionIndex = change.insertionIndex
                mostRecentInsertionIndex = change.insertionIndex
                initialValue = newValue
                mostRecentValue = newValue
                // We early exit in this case, since we've already created the phrase that the timer would create.
                return
                
            }
            
            // Also looking for big changes in the insertion index, which could signify a phrase completion.
            // This is our main 'weird' case. We don't want to include the latest update in the phrase.
            if let currentInsertionIndex = change.insertionIndex {
                if let unwrappedRecentInsertionIndex = mostRecentInsertionIndex, let unwrappedInitialInsertionIndex = initialInsertionIndex {
                    // This is an edge case where the cursor moves dramatically. If you stay within the bounds of your edit
                    // defined here as within 5 characters of the start/most recent index, then we don't do anything. If you're outside
                    // of the bounds, we finish the phrase and start a new one. 
                    if abs(currentInsertionIndex - unwrappedRecentInsertionIndex) > 5 && abs(currentInsertionIndex - unwrappedInitialInsertionIndex) > 5 {
                        finishPhrase(element: element, endValue: mostRecentValue, trigger: "cursorJump")
                        initialValue = newValue
                        initialInsertionIndex = currentInsertionIndex
                        // We don't exit in this case, even though we've created a phrase. That's because this is the start of a new phrase, so we should the timer.
                    }
                }
                mostRecentInsertionIndex = currentInsertionIndex
            }
        } else {
            print("typeaheadDebug - ignore notif, no change")
        }

        mostRecentValue = newValue
        
        // Otherwise, listen for 1s stops in the typing.
        valueDebounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.finishPhrase(element: element, endValue: self.mostRecentValue, trigger: "timeout")
            initialValue = newValue
            mostRecentValue = newValue
        }

        valueDebounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + TypingChangeDelegate.Config.typingDebounceInterval, execute: workItem)
    }
    
    // MARK: - Fast Bi-directional String Difference Algorithm
    
    private func calculateTextChangeFast(from oldValue: String?, to newValue: String?) -> TextChange? {
        guard let old = oldValue, let new = newValue else { 
            let result = newValue != nil ? TextChange(type: .addition, addedText: newValue, deletedText: nil, insertionIndex: 0, textPrefixRange: nil, textSuffixRange: nil) : nil
            print("typeaheadDebug - calculateTextChangeFast guard return: \(result?.type.rawValue ?? "nil")")
            return result
        }
        
        if old == new { 
            print("typeaheadDebug - calculateTextChangeFast no change return: nil")
            return nil 
        }
        
        let initialChars = Array(old)
        let newChars = Array(new)
        
        // Find common prefix
        var prefixLength = 0
        let minLength = min(initialChars.count, newChars.count)
        
        while prefixLength < minLength && initialChars[prefixLength] == newChars[prefixLength] {
            prefixLength += 1
        }
        
        // Find common suffix
        var suffixLength = 0
        let maxSuffixLength = minLength - prefixLength
        
        while suffixLength < maxSuffixLength && 
              initialChars[initialChars.count - 1 - suffixLength] == newChars[newChars.count - 1 - suffixLength] {
            suffixLength += 1
        }
        
        // Calculate what changed
        let initialMiddleStart = prefixLength
        let initialMiddleEnd = initialChars.count - suffixLength
        let newMiddleStart = prefixLength
        let newMiddleEnd = newChars.count - suffixLength
        
        let deletedText = initialMiddleStart < initialMiddleEnd ? 
            String(initialChars[initialMiddleStart..<initialMiddleEnd]) : ""
        let addedText = newMiddleStart < newMiddleEnd ? 
            String(newChars[newMiddleStart..<newMiddleEnd]) : ""
        
        // Calculate prefix and suffix from the new text
        let textPrefixRange = prefixLength > 0 ? NSRange(location: 0, length: prefixLength) : nil
        let textSuffixRange = suffixLength > 0 ? NSRange(location: newChars.count - suffixLength, length: suffixLength) : nil
        
        // Determine change type and return appropriate result
        if deletedText.isEmpty && !addedText.isEmpty {
            let result = TextChange(type: .addition, addedText: addedText, deletedText: nil, insertionIndex: prefixLength, textPrefixRange: textPrefixRange, textSuffixRange: textSuffixRange)
            return result
        } else if !deletedText.isEmpty && addedText.isEmpty {
            let result = TextChange(type: .deletion, addedText: nil, deletedText: deletedText, insertionIndex: prefixLength, textPrefixRange: textPrefixRange, textSuffixRange: textSuffixRange)
            return result
        } else if !deletedText.isEmpty && !addedText.isEmpty {
            let result = TextChange(type: .modification, addedText: addedText, deletedText: deletedText, insertionIndex: prefixLength, textPrefixRange: textPrefixRange, textSuffixRange: textSuffixRange)
            return result
        }
        
        return nil
    }
    
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didFocusTextElement element: AXUIElement,
        window: TrackedWindow?
    ) {
        let elementId: UInt = CFHash(element)
        if elementId != focusedTextFieldId {
            print("typeaheadDebug - focus event, setting initial value")
            // We set the initial value on the first focus event.
            focusedTextFieldId = elementId
            focusedTextElement = element
            initialValue = element.value()
            mostRecentValue = initialValue
            initialInsertionIndex = nil
            onTextFocused(element)
        } else {
            print("typeaheadDebug - duplicate textfield focus event, skipping")
        }
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
    
    private func addToContentHistoryIfNeeded(_ window: TrackedWindow) {
        if Defaults[.collectTypeaheadTestCases] {
             Task {
                 AccessibilityParsingManager.shared.requestParsing(for: window.element, requester: self, completion: { result in
                     switch result {
                     case .success(let parsedResult):
                         print("typeaheadDebugParsing - loaded context from window named: \(window.title)")
                        
                         // Extract data from parsing result
                         let screenContent = parsedResult["screen"] ?? ""
                         let applicationName = parsedResult["applicationName"] ?? window.pid.appName ?? "Unknown"
                         let applicationTitle = parsedResult["applicationTitle"] ?? window.title
                         let elapsedTime = Double(parsedResult["elapsedTime"] ?? "0") ?? 0.0
                        
                         Task {
                             await TypeaheadHistoryManager.shared.addContent(
                                content: screenContent,
                                applicationName: applicationName,
                                applicationTitle: applicationTitle,
                                method: "accessibility",
                                elapsedTime: elapsedTime)
                         }
                         
                      case .failure(let error):
                         print("typeaheadDebugParsing - failed to load context from window: \(error)")
                     }
                 })
             }
        }
        focusedTextFieldId = nil
        focusedTextElement = nil
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        addToContentHistoryIfNeeded(window)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow) {
        addToContentHistoryIfNeeded(window)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateOnit window: TrackedWindow) {
        addToContentHistoryIfNeeded(window)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeWindowTitle window: TrackedWindow) {}
}

extension TypingChangeDelegate {
    struct Config {
        static let typingDebounceInterval: TimeInterval = 3.0 // 1s
        static let rateLimitWindow: TimeInterval = 1.0 // 1 second window
        static let maxCharactersPerWindow: Int = 20 // Maximum 20 characters per second
    }
}
