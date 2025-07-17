//
//  TypeaheadLearningManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 6/18/25.
//

import Defaults
import Foundation
import AppKit
import Combine

@MainActor
final class TypeaheadLearningService: @unchecked Sendable {

    static let shared = TypeaheadLearningService()
    
    private var typingChangeDelegate: TypingChangeDelegate?
    private var cancellables = Set<AnyCancellable>()
    private var activeTypingElementHash: UInt = 0

    @Default(.collectTypeaheadTestCases) var collectTypeaheadTestCases
    
    private init() {
        // Start monitoring the setting changes
        setupSettingObserver()
        
        // Initialize based on current setting
        if collectTypeaheadTestCases {
            startTypeaheadLearning()
        }
    }
    
    private func setupSettingObserver() {
        // Listen for changes to the collectTypeaheadTestCases setting
        Defaults.publisher(.collectTypeaheadTestCases)
            .sink { [weak self] change in
                if change.newValue {
                    self?.startTypeaheadLearning()
                } else {
                    self?.stopTypeaheadLearning()
                }
            }
            .store(in: &cancellables)
    }
    
    func startTypeaheadLearning() {
        guard typingChangeDelegate == nil else {
            print("startTypeaheadLearning: delegate already exists")
            return
        }

        print("TypeaheadLearningService: Starting typeahead learning")
        
        typingChangeDelegate = TypingChangeDelegate(
            onPhraseEntered: { [weak self] element, newValue, textChange, keystrokes, couldntFindInitialText in
                self?.handlePhraseEntered(element: element, newValue: newValue, textChange: textChange, keystrokes: keystrokes, couldntFindInitialText: couldntFindInitialText)
            },
            onTextFocused: { [weak self] element in
                self?.handleTextFocused(element: element)
            }
        )
        
        AccessibilityNotificationsManager.shared.addDelegate(typingChangeDelegate!)
    }
    
    private func handlePhraseEntered(element: AXUIElement?, newValue: String?, textChange: TextChange?, keystrokes: [String], couldntFindInitialText: Bool) {
        guard let element = element else { return }
        
        let addedText = textChange?.addedText ?? ""
        let deletedText = textChange?.deletedText ?? ""
        let changeTypeString = textChange?.type.rawValue ?? "unknown"
        //print("typeaheadPhraseDebug - Phrase Cange: \(changeTypeString) - \(textChange?.trigger ?? "") - added: \(textChange?.addedText ?? "") deleted: \(textChange?.deletedText ?? ""))")
        
        // Extract prefix and suffix text from ranges
        var prefixText = ""
        var suffixText = ""
        
        if let textChange = textChange, let newValue = newValue {
            // TODO: Tim - this still has an out of bounds error.
            // TODO: Tim - the prefix/suffix code needs to only 'take' the number of chracters available.
            prefixText = textChange.textPrefixRange != nil ? (newValue as NSString).substring(with: textChange.textPrefixRange!) : ""
            suffixText = textChange.textSuffixRange != nil ? (newValue as NSString).substring(with: textChange.textSuffixRange!) : ""
            print("typeaheadPhraseDebugPrefix - \(changeTypeString): prefix='\(prefixText)', suffix='\(suffixText)', keystrokes: \(keystrokes)")
        }
        
        print("typeaheadPhraseDebuSave - ===== new one")
        print("typeaheadPhraseDebuSave - added: \(addedText)")
        print("typeaheadPhraseDebuSave - removed: \(deletedText)")
        print("typeaheadPhraseDebuSave - type: \(changeTypeString)")
        
        // TODO: Process the value change for typeahead learning
        // This is where you would:
        // 2. Store this information for learning
        
        Task { @MainActor in 
            let (precedingWindowText, followingWindowText) = await AccessibilityParsingManager.shared.splitTextAroundElement(element)
            // Store this typing pattern in the history manager
            let app = element.appName() ?? ""
            let windowTitle = element.title() ?? ""
            
            await TypeaheadHistoryManager.shared.addTypedPhrase(
                applicationName: app,
                applicationTitle: windowTitle,
                screenContent: "", // Could add more context here
                currentText: newValue ?? "",
                precedingInputText: prefixText,
                followingInputText: suffixText,
                preceedingWindowText: precedingWindowText,
                followingWindowText: followingWindowText,
                addedText: addedText,
                deletedText: deletedText,
                changeType: changeTypeString,
                keystrokes: keystrokes,
                couldntFindInitialText: couldntFindInitialText
            )
        }
    }
    
    private func handleTextFocused(element: AXUIElement?) {
        guard let element = element else { return }
        
        print("TypeaheadLearningService - Text element focused")
        
        activeTypingElementHash = CFHash(element)
    }
    
    func stopTypeaheadLearning() {
        if let delegate = typingChangeDelegate {
            AccessibilityNotificationsManager.shared.removeDelegate(delegate)
            typingChangeDelegate = nil
            print("TypeaheadLearningService: Stopped typeahead learning")
        }
    }
}
