//
//  PreferencesView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/17/24.
//

import Defaults
import KeyboardShortcuts
import SwiftData
import SwiftUI

struct TextInputView: View {
    @Environment(\.model) var model

    @FocusState var focused: Bool

    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]

    @Default(.mode) var mode
    
    @State private var textHeight: CGFloat = 20
    @State private var isProcessingURL: Bool = false
    private let maxHeightLimit: CGFloat = 100

    var body: some View {
        HStack(alignment: .bottom) {
            textField
            sendButton
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
        .padding(.horizontal, 16)
        .background {
            upListener
            downListener
            newListener
        }
    }

    @ViewBuilder
    var textField: some View {
        @Bindable var model = model

        ZStack(alignment: .leading) {
            TextViewWrapper(
                text: $model.pendingInstruction,
                dynamicHeight: $textHeight,
                onSubmit: sendAction,
                maxHeight: maxHeightLimit,
                placeholder: placeholderText)
            .focused($focused)
            .frame(height: min(textHeight, maxHeightLimit))
            .onAppear { focused = true }
            .onChange(of: model.textFocusTrigger) { focused = true }
            .onChange(of: model.pendingInstruction) { oldValue, newValue in
                // Check for URLs when text changes
                if !isProcessingURL && !newValue.isEmpty {
                    Task {
                        await checkForURLs()
                    }
                }
            }
        }
        .appFont(.medium16)
        .foregroundStyle(.white)
        .overlay(alignment: .topTrailing) {
            if isProcessingURL {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.trailing, 8)
                    .padding(.top, 4)
            }
        }
    }

    var placeholderText: String {
        if let currentChat = model.currentChat {
            if !currentChat.isEmpty {

                if let keyboardShortcutString = KeyboardShortcuts.getShortcut(for: .newChat)?
                    .description
                {
                    "Follow-up... (" + keyboardShortcutString + " for new)"
                } else {
                    "Follow-up..."
                }

            } else {
                "New instructions..."
            }
        } else {
            "New instructions..."
        }
    }
    
    /// Checks for URLs in the pending instruction and processes them
    func checkForURLs() async {
        guard !model.pendingInstruction.isEmpty else { return }
        
        // Set processing state
        await MainActor.run {
            isProcessingURL = true
        }
        
        // Process text for URLs
        let (processedText, foundURLs) = await WebContentContext.processTextForURLs(
            text: model.pendingInstruction, 
            model: model
        )
        
        // Update UI with processed text if URLs were found
        await MainActor.run {
            if foundURLs {
                model.pendingInstruction = processedText
            }
            isProcessingURL = false
        }
    }

    func sendAction() {
        let inputText = model.pendingInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add empty check
        guard !inputText.isEmpty else { return }
        
        // Final URL check before sending
        if !isProcessingURL {
            Task {
                await checkForURLs()
                await MainActor.run {
                    model.createAndSavePrompt()
                }
            }
        } else {
            // If we're still processing, wait a bit and then send
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    model.createAndSavePrompt()
                }
            }
        }
    }

    var sendButton: some View {
        Button(action: sendAction) {
            Image(mode == .local ? .circleArrowUpDotted : .circleArrowUp)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(
                    model.pendingInstruction.isEmpty
                        ? Color.gray700 : (mode == .local ? .limeGreen : Color.blue400)
                )
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .disabled(model.pendingInstruction.isEmpty || isProcessingURL)
        .keyboardShortcut(.return, modifiers: [])
    }

    var upListener: some View {
        Button {
            guard !chats.isEmpty else { return }

            if model.historyIndex + 1 < chats.count {
                model.historyIndex += 1
                model.currentChat = chats[model.historyIndex]
                model.currentPrompts = chats[model.historyIndex].prompts
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.upArrow, modifiers: [])
    }

    var downListener: some View {
        Button {
            if model.historyIndex > 0 {
                model.historyIndex -= 1
                model.currentChat = chats[model.historyIndex]
                model.currentPrompts = chats[model.historyIndex].prompts
            } else if model.historyIndex == 0 {
                model.historyIndex = -1
                model.currentChat = nil
                model.currentPrompts = nil
                focused = true
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.downArrow, modifiers: [])
    }

    var newListener: some View {
        Button {
            model.newChat()
        } label: {
            EmptyView()
        }
        .keyboardShortcut("n")
    }
}

#Preview {
    TextInputView()
}

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            insertionPointColor = .white
        }
    }
}
