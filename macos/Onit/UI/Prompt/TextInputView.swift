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
        }
        .appFont(.medium16)
        .foregroundStyle(.white)
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

    func sendAction() {
        let inputText = model.pendingInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add empty check
        guard !inputText.isEmpty else { return }
        
        model.createAndSavePrompt()
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
        .disabled(model.pendingInstruction.isEmpty)
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
