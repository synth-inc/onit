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
            onValueChanged: { [weak self] element, newValue in
                self?.handleValueChanged(element: element, newValue: newValue)
            },
            onTextFocused: { [weak self] element in
                self?.handleTextFocused(element: element)
            }
        )
        
        AccessibilityNotificationsManager.shared.addDelegate(typingChangeDelegate!)
    }
    
    private func handleValueChanged(element: AXUIElement?, newValue: String?) {
        guard let element = element else { return }
        
        print("TypeaheadLearningService - Value changed: \(newValue ?? "nil")")
        
        // TODO: Process the value change for typeahead learning
        // This is where you would:
        // 1. Extract the typing context (preceding text, current text, following text)
        // 2. Store this information for learning
        // 3. Generate typeahead suggestions based on learned patterns
        
        Task {
            let (precedingText, followingText) = await AccessibilityParsingManager.shared.splitTextAroundElement(element)
            
            // Store this typing pattern in the history manager
            if let app = element.appName(),
               let windowTitle = element.title() {
                TypeaheadHistoryManager.shared.typedInput.add(
                    applicationName: app,
                    applicationTitle: windowTitle,
                    screenContent: "", // Could add more context here
                    currentText: newValue ?? "",
                    precedingText: precedingText ?? "",
                    followingText: followingText ?? "",
                    aiCompletion: nil,
                    similarityScore: nil
                )
            }
        }
    }
    
    private func handleTextFocused(element: AXUIElement?) {
        guard let element = element else { return }
        
        print("TypeaheadLearningService - Text element focused")
        
        // TODO: Process the text focus event for typeahead learning
        // This is where you would:
        // 1. Initialize context for the focused text element
        // 2. Prepare for capturing typing patterns
    }
    
    func stopTypeaheadLearning() {
        if let delegate = typingChangeDelegate {
            AccessibilityNotificationsManager.shared.removeDelegate(delegate)
            typingChangeDelegate = nil
            print("TypeaheadLearningService: Stopped typeahead learning")
        }
    }
}
