//
//  TypingChangeDelegate.swift
//  Onit
//
//  Created by Timothy Lenardo on 6/18/25.
//

import Foundation
import AppKit
import Defaults
import ApplicationServices

// MARK: - Typing Change Info

private struct AccessibilityValue {
    let elementId: UInt
    let newValue: String?
}
struct TypingSession {
    var initialText: String = ""
    var currentText: String = ""
    var keystrokes: [String] = []  // All keystrokes, output and non-output
    var couldntFindInitialText: Bool = false
    var startTime: Date = Date()
    var lastKeystroke: Date = Date()

    var element: AXUIElement?
    var elementId: UInt?
   
    // TODO: Tim - keep a list of the keystrokes that got us from initialText to currentText. 

    mutating func updateText(_ newText: String, readableKey: String) {
        currentText = newText
        addKeystroke(readableKey: readableKey)
    }
    
    mutating func addKeystroke(readableKey: String) {
        lastKeystroke = Date()
        keystrokes.append(readableKey)
    }
   
    var timeSinceLastKeystroke: TimeInterval {
        Date().timeIntervalSince(lastKeystroke)
    }
   
    var totalDuration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
}

// MARK: - Typing Change Delegate

final class TypingChangeDelegate: AccessibilityNotificationsDelegate, KeystrokeNotificationDelegate {
    // MARK: - Properties
    
    private var focusedTextFieldId: UInt? = nil
    private var focusedTextElement: AXUIElement? = nil
    
    private var currentSession: TypingSession?
    private var phraseDebounceWorkItem: DispatchWorkItem?
    
    // MARK: - Keystroke Notification Delegate
    
    // Removed keystrokeManager property as it's now managed by KeystrokeNotificationManager.shared

    private let onPhraseEntered: (AXUIElement?, String?, TextChange?, [String], Bool) -> Void  // Changed [Int64] to [String]
    private let onTextFocused: (AXUIElement?) -> Void
    
    init(onPhraseEntered: @escaping (AXUIElement?, String?, TextChange?, [String], Bool) -> Void, onTextFocused: @escaping (AXUIElement?) -> Void) {  // Changed [Int64] to [String]
        self.onPhraseEntered = onPhraseEntered
        self.onTextFocused = onTextFocused
        setupDelegateRegistration()
    }
    
    // Removed deinit block as it's no longer needed

    func keystrokeNotificationManager(_ manager: KeystrokeNotificationManager, didReceiveKeystroke event: KeystrokeEvent) {
        // Process keystrokes only when focused on a text element
        guard let focusedElement = self.focusedTextElement else {
            print("TypingChangeDelegate: No focused element, ignoring keystroke.")
            return
        }
        // We need to read beforeText before the delay. 
        let beforeText = focusedElement.value() ?? ""

        let elementId = CFHash(focusedElement)
        if elementId == self.focusedTextFieldId {
            print("TypingChangeDelegate: Handling keystroke for focused element.")
            
            // Process text change after a short delay to allow the system to update the text value
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.handleTextChange(element: focusedElement, beforeText: beforeText, modifierStates: event.modifierStates, keyCode: Int64(event.keyCode))
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupDelegateRegistration() {
        // Register TypingChangeDelegate with KeystrokeNotificationManager
        KeystrokeNotificationManager.shared.addDelegate(self)
        
        // Start monitoring if not already started (this might be redundant if AppCoordinator already does it, but ensures it if not)
        KeystrokeNotificationManager.shared.startMonitoring()
    }

    // MARK: - Text Processing
    // TODO: TIm - remove beforeText.
    private func handleTextChange(element: AXUIElement, beforeText: String, modifierStates: (command: Bool, control: Bool, shift: Bool, option: Bool), keyCode: Int64) {
        let elementId = CFHash(element)
    
        let keyProducesOutput = KeyCodeTranslator.shared.keyProducesOutputWithModifiers(keyCode, modifierStates: modifierStates)
        let readableKey = KeyCodeTranslator.shared.translateKeyCodeWithModifiers(keyCode, modifierStates: modifierStates)

        if keyProducesOutput {
            if currentSession == nil {
                // TODO: Tim - This logic is not working becuase of common overlap cases.For example, if the text field becomes empty and has been empty in the past, it will choose some random starting point.
                // Search for the first entry in the buffer whose newValue matches afterText

                var currentText = beforeText
                var couldntFindInitialText = true
                if let currentValue = element.value() {
                    couldntFindInitialText = false
                    currentText = currentValue
                }
                
                // Start the new session.
                var newSession = TypingSession()
                newSession.element = element
                newSession.elementId = elementId
                newSession.initialText = beforeText
                newSession.currentText = currentText
                newSession.couldntFindInitialText = couldntFindInitialText
                currentSession = newSession
                
            }
            
            if let currentValue = element.value() {
                currentSession?.updateText(currentValue, readableKey: readableKey)
            } else {
                currentSession?.addKeystroke(readableKey: readableKey)
            }
            
            if isPhraseCompletionCharacter(readableKey) {
                finishCurrentPhrase(trigger: "phraseEndCharacter")
                return
            }
        
            // Handle special keys that should complete phrases
            if isPhraseTriggerKey(keyCode: keyCode) {
                finishCurrentPhrase(trigger: "specialKey")
                return
            }
            
            // Set up debounce timer
            schedulePhraseDebouncedCompletion()
        } else {
            // If we're in a session, add the keystroke for debugging purposes.
            if currentSession != nil {
                currentSession?.addKeystroke(readableKey: readableKey)
            }
        }
    }
    
    private func isPhraseTriggerKey(keyCode: Int64) -> Bool {
        switch keyCode {
        case 36: // Return/Enter
            return true
        default:
            return false
        }
    }
    
    // MARK: - Text Difference Calculation (Moved to TextChangeHelper)
    
    private func isPhraseCompletionCharacter(_ char: String) -> Bool {
        return char == "." || char == "shift+!" || char == "shift+?" 
        // TODO: Tim - what is \r and do we need it?
        // || char == "\n" || char == "\r"
    }
    
    private func schedulePhraseDebouncedCompletion() {
        phraseDebounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.finishCurrentPhrase(trigger: "timeout")
        }
        
        phraseDebounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Config.typingDebounceInterval, execute: workItem)
    }
    
    private func finishCurrentPhrase(trigger: String) {
        guard let session = currentSession else { return }
        if let focusedTextElement = focusedTextElement,
           let finalText = focusedTextElement.value() {
            let textChange = TextChangeHelper.shared.calculateTextChangeFast(from: session.initialText, to: finalText, keystrokes: session.keystrokes)
            
            if var unwrappedTextChange = textChange {
                unwrappedTextChange.trigger = trigger
                unwrappedTextChange.initialText = session.initialText
                unwrappedTextChange.endText = finalText
                
                print("typeaheadDebug - Finishing session: ============== \(trigger) ===================")
                print("typeaheadDebug - Finishing session: type \(textChange?.type.rawValue)")
                print("typeaheadDebug - Finishing session: deleted \(textChange?.deletedText ?? "nil")")
                print("typeaheadDebug - Finishing session: added \(textChange?.addedText ?? "nil")")
                
                onPhraseEntered(session.element, finalText, unwrappedTextChange, session.keystrokes, session.couldntFindInitialText)
            }
        }
        currentSession = nil
        phraseDebounceWorkItem?.cancel()
    }
    
    // MARK: - Utility Methods (Removed old value change logic)
    
    // MARK: - AccessibilityNotificationsDelegate Implementation
    
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didChangeValue element: AXUIElement,
        newValue: String?,
        window: TrackedWindow?
    ) {
        let elementId = CFHash(element)
        if elementId == focusedTextFieldId {
            print("typeaheadDebug - didChangeValue - \(element.appName() ?? "Unknown")")
        }
    }
    
    // MARK: - Legacy Methods (Removed old text difference algorithm)
    
    // TODO: Tim - We might want to end the session on any focusEvent, not just text field..? I'm not sure, I think the debounce timer should handle that.
    // The weirdness happens when you can type in something that isn't a text field.
    // The current keystroke based approach will register new text without a corresponding textField.
    
    func accessibilityManager(
        _ manager: AccessibilityNotificationsManager,
        didFocusUIElement element: AXUIElement,
        window: TrackedWindow?
    ) {
        
        guard let role = element.role(), [kAXTextFieldRole, kAXTextAreaRole].contains(role) else {
            print("typeaheadDebug - didFocusTextElement - skipping non-text-field element: \(element.role() ?? "")")
            finishCurrentPhrase(trigger: "focusChange")
            focusedTextFieldId = nil
            focusedTextElement = nil
            return
        }
        
        // Okay, so we've focused a text element.
        let elementId: UInt = CFHash(element)
        if elementId != focusedTextFieldId {
            // Finish any current session before switching elements
            if element.appName() != focusedTextElement?.appName() {
                finishCurrentPhrase(trigger: "appChange")
            } else {
                finishCurrentPhrase(trigger: "elementChange")
            }
            
            // Update focused element
            focusedTextFieldId = elementId
            focusedTextElement = element
            
            onTextFocused(element)
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
    }
    
    func resetSessionOnWindowChangeIfNeeded(newWindow: TrackedWindow) {
        // This check is needed when a first click activates a textField and application.
        // The focusedUIElement notification can come first, meaning we start a new session.
        // Then the 'didActivateWindow' notification comes. Without this check, we'll immediately end the new session.
        // That ain't right! We should keep that session going.
        if let newApp = newWindow.element.appName(),
           let currentSessionApp = currentSession?.element?.appName(),
           newApp != currentSessionApp {
            finishCurrentPhrase(trigger: "appChange")
            focusedTextFieldId = nil
            focusedTextElement = nil
        }
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
    
    /// TypingChangeDelegate needs notifications from ALL processes for typeahead learning,
    /// including Onit's own process and ignored applications like Xcode
    var wantsNotificationsFromAllProcesses: Bool { true }
}
