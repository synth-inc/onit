//
//  PreferencesView.swift
//  Omni
//
//  Created by Benjamin Sage on 9/17/24.
//

import SwiftUI
import SwiftData

struct TextInputView: View {
    @Environment(\.model) var model

    @FocusState var focused: Bool

    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]

    var body: some View {
        HStack {
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
            TextField("", text: $model.pendingInstruction, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($focused)
                .tint(.blue600.opacity(0.2))
                .fixedSize(horizontal: false, vertical: true)
                .onAppear {
                    focused = true
                }
                .onChange(of: model.textFocusTrigger) {
                    focused = true
                }

            if model.pendingInstruction.isEmpty {
                placeholderView
            } else {
                Text(" ")
            }
        }
        .appFont(.medium16)
        .foregroundStyle(.white)
    }

    var placeholderText: String {
        if let currentChat = model.currentChat {
            if !currentChat.isEmpty {
                "Follow-up... (⌃N for new)"
            } else {
                "New instructions..."
            }
        } else {
            "New instructions..."
        }
    }

    var placeholderView: some View {
        HStack {
            Text(placeholderText)
        }
        .foregroundStyle(.gray300)
        .allowsHitTesting(false)
    }

    func sendAction() {
        let newPrompt = model.createAndSavePrompt()
        model.generate(newPrompt)
    }

    var sendButton: some View {
        Button(action: sendAction) {
            Image(model.preferences.mode == .local ? .circleArrowUpDotted : .circleArrowUp)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(model.pendingInstruction.isEmpty ? Color.gray700 : (model.preferences.mode == .local ? .limeGreen : Color.blue400))
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
