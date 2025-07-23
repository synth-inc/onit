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
    var keystrokes: [String] = []  // Output-producing keystrokes
    var nonOutputKeystrokes: [String] = []  // Non-output-producing keystrokes
    var couldntFindInitialText: Bool = false
    var startTime: Date = Date()
    var lastKeystroke: Date = Date()

    var element: AXUIElement?
    var elementId: UInt?
   
    // TODO: Tim - keep a list of the keystrokes that got us from initialText to currentText. 

    mutating func updateText(_ newText: String, readableKey: String) {
        currentText = newText
        addOutputKeystroke(readableKey: readableKey)
    }
    
    mutating func addOutputKeystroke(readableKey: String) {
        lastKeystroke = Date()
        keystrokes.append(readableKey)
    }
    
    mutating func addNonOutputKeystroke(readableKey: String) {
        lastKeystroke = Date()
        nonOutputKeystrokes.append(readableKey)
    }
   
    var timeSinceLastKeystroke: TimeInterval {
        Date().timeIntervalSince(lastKeystroke)
    }
   
    var totalDuration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
}

// MARK: - Typing Change Delegate

final class TypingChangeDelegate: AccessibilityNotificationsDelegate {
    // MARK: - Keyboard Monitoring Properties
    
    private nonisolated(unsafe) var eventTap: CFMachPort?
    private nonisolated(unsafe) var runLoopSource: CFRunLoopSource?
    
    private var focusedTextFieldId: UInt? = nil
    private var focusedTextElement: AXUIElement? = nil
    
    private var currentSession: TypingSession?
    private var phraseDebounceWorkItem: DispatchWorkItem?
    
    // MARK: - Modifier Key Tracking
    
    private var isCommandPressed: Bool = false
    private var isControlPressed: Bool = false
    private var isShiftPressed: Bool = false
    private var isOptionPressed: Bool = false
    
    private let onPhraseEntered: (AXUIElement?, String?, TextChange?, [String], Bool) -> Void  // Changed [Int64] to [String]
    private let onTextFocused: (AXUIElement?) -> Void
    
    init(onPhraseEntered: @escaping (AXUIElement?, String?, TextChange?, [String], Bool) -> Void, onTextFocused: @escaping (AXUIElement?) -> Void) {  // Changed [Int64] to [String]
        self.onPhraseEntered = onPhraseEntered
        self.onTextFocused = onTextFocused
        startKeyboardMonitoring()
    }
    
    deinit {
        // Clean up synchronously in deinit
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            }
        }
    }
    
    // MARK: - Keyboard Monitoring
    
    private func startKeyboardMonitoring() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                
   
                let delegate = Unmanaged<TypingChangeDelegate>.fromOpaque(refcon).takeUnretainedValue()
                delegate.handleKeyboardEvent(type: type, event: event)
                
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("typeaheadDebug - Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("typeaheadDebug - Keyboard monitoring started")
    }
    
    private func stopKeyboardMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            
            self.eventTap = nil
            self.runLoopSource = nil
        }
        
        print("typeaheadDebug - Keyboard monitoring stopped")
    }
    
    private func handleKeyboardEvent(type: CGEventType, event: CGEvent) {
        print("typeaheadDebug - handleKeyboardEvent | type: \(type)")
        switch type {
        case .flagsChanged:
            self.updateModifierKeys(event: event)
        case .keyDown:
            self.handleKeyDown(event: event)
        case .keyUp:
            self.handleKeyUp(event: event)
        case .tapDisabledByUserInput:
            self.restartEventTapIfNeeded()
        case .tapDisabledByTimeout:
            self.restartEventTapIfNeeded()
        default:
            break
        }
    }
    
    private func restartEventTapIfNeeded() {
        if let eventTap = self.eventTap {
            DispatchQueue.main.async {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
        }
    }
    
    private func updateModifierKeys(event: CGEvent) {
        let flags = event.flags
        isCommandPressed = flags.contains(.maskCommand)
        isControlPressed = flags.contains(.maskControl)
        isShiftPressed = flags.contains(.maskShift)
        isOptionPressed = flags.contains(.maskAlternate)
    }
    
    private func handleKeyDown(event: CGEvent) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        print("typeaheadDebug - timlx - CGEvent - handleKeyDown | keyCode: \(keyCode)")
        
        // Only process typing when focused on a text element
        // This means we ignore the ignored apps from the main AXNotificationObserver, since they won't have provided us with a focusedTextElement.
        guard let focusedElement = focusedTextElement else {
            print("typeaheadDebug - no focused element, early return")
            return
        }
        
        if let beforeText = focusedElement.value() {
            // Schedule text change detection after a short delay to let the keystroke process
            DispatchQueue.main.async { [weak self] in
                self?.handleTextChange(element: focusedElement, beforeText: beforeText, keyCode: keyCode)
            }
        }
    }
    
    private func handleKeyUp(event: CGEvent) {
        // Currently not needed for our use case
    }
    
    // MARK: - Text Processing
    // TODO: TIm - remove beforeText.
    private func handleTextChange(element: AXUIElement, beforeText: String, keyCode: Int64) {
        let elementId = CFHash(element)
    
        // Update session with current modifier states
        let modifierStates = (command: isCommandPressed, control: isControlPressed, shift: isShiftPressed, option: isOptionPressed)
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
                currentSession?.addOutputKeystroke(readableKey: readableKey)
            }
            
            if isPhraseCompletionCharacter(readableKey) {
                finishCurrentSession(trigger: "phraseEndCharacter")
                return
            }
        
            // Handle special keys that should complete phrases
            if isPhraseTriggerKey(keyCode: keyCode) {
                finishCurrentSession(trigger: "specialKey")
                return
            }
            
            // Set up debounce timer
            schedulePhraseDebouncedCompletion()
        } else {
            // If we're in a session, add the non-output keystroke for debugging purposes.
            if currentSession != nil {
                currentSession?.addNonOutputKeystroke(readableKey: readableKey)
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
            self?.finishCurrentSession(trigger: "timeout")
        }
        
        phraseDebounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Config.typingDebounceInterval, execute: workItem)
    }
    
    private func finishCurrentSession(trigger: String) {
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
            finishCurrentSession(trigger: "focusChange")
            focusedTextFieldId = nil
            focusedTextElement = nil
            return
        }
        
        // Okay, so we've focused a text element.
        let elementId: UInt = CFHash(element)
        if elementId != focusedTextFieldId {
            // Finish any current session before switching elements
            if element.appName() != focusedTextElement?.appName() {
                finishCurrentSession(trigger: "appChange")
            } else {
                finishCurrentSession(trigger: "elementChange")
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
            finishCurrentSession(trigger: "appChange")
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
