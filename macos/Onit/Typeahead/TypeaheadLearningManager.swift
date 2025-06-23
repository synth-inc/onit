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
            onPhraseEntered: { [weak self] element, newValue, textChange in
                self?.handlePhraseEntered(element: element, newValue: newValue, textChange: textChange)
            },
            onTextFocused: { [weak self] element in
                self?.handleTextFocused(element: element)
            }
        )
        
        AccessibilityNotificationsManager.shared.addDelegate(typingChangeDelegate!)
    }
    
    private func handlePhraseEntered(element: AXUIElement?, newValue: String?, textChange: TextChange?) {
        guard let element = element else { return }
        
        let changeText = textChange?.addedText ?? ""
        let changeTypeString = textChange?.type.rawValue ?? "unknown"
        //print("typeaheadPhraseDebug - Phrase Cange: \(changeTypeString) - \(textChange?.trigger ?? "") - added: \(textChange?.addedText ?? "") deleted: \(textChange?.deletedText ?? ""))")
        
        // Extract prefix and suffix text from ranges
        var prefixText = ""
        var suffixText = ""
        
        if let textChange = textChange, let newValue = newValue {
            prefixText = textChange.textPrefixRange != nil ? (newValue as NSString).substring(with: textChange.textPrefixRange!) : ""
            suffixText = textChange.textSuffixRange != nil ? (newValue as NSString).substring(with: textChange.textSuffixRange!) : ""
            print("typeaheadPhraseDebugPrefix - \(changeTypeString): prefix='\(prefixText)', suffix='\(suffixText)'")
        }
        
        // TODO: Process the value change for typeahead learning
        // This is where you would:
        // 2. Store this information for learning
        
        Task {
            let (precedingWindowText, followingWindowText) = await AccessibilityParsingManager.shared.splitTextAroundElement(element)
            
            
            // Store this typing pattern in the history manager
            if let app = element.appName() {
                let windowTitle = element.title() ?? ""
                TypeaheadHistoryManager.shared.typedPhrase.add(
                    applicationName: app,
                    applicationTitle: windowTitle,
                    screenContent: "", // Could add more context here
                    currentText: newValue ?? "",
                    precedingInputText: prefixText,
                    followingInputText: suffixText,
                    preceedingWindowText: precedingWindowText,
                    followingWindowText: followingWindowText,
                    changeText: changeText,
                    changeType: changeTypeString
                )
            }
        }
    }
    
    private func handleTextFocused(element: AXUIElement?) {
        guard let element = element else { return }
        
        print("TypeaheadLearningService - Text element focused")
        
        activeTypingElementHash = CFHash(element)
        
        // We should get the AXScrape if it doesn't already exist.
//        Task {
//            AccessibilityParsingManager.shared.requestParsing(for: windowElement, requester: self, completion: { _ in
//                // No-op - just establishing cache
//            })
//        }
    }
    
    func stopTypeaheadLearning() {
        if let delegate = typingChangeDelegate {
            AccessibilityNotificationsManager.shared.removeDelegate(delegate)
            typingChangeDelegate = nil
            print("TypeaheadLearningService: Stopped typeahead learning")
        }
    }
}
