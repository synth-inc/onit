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
    
    @State private var isProcessingURLs = false

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
                if !isProcessingURLs && !newValue.isEmpty {
                    Task {
                        await checkForURLs()
                    }
                }
            }
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
    
    /// Checks for URLs in the pending instruction and processes them
    func checkForURLs() async {
        guard !model.pendingInstruction.isEmpty else { return }
        
        isProcessingURLs = true
        defer { isProcessingURLs = false }
        
        let urls = URLDetector.detectURLs(in: model.pendingInstruction)
        
        for url in urls {
            let urlHost = url.host ?? "URL"
            
            let isDuplicate = await model.pendingContextList.contains { context in
                if case .webAuto(let appName, _, _) = context {
                    return appName == "Web: \(urlHost)"
                }
                if case .auto(let appName, _) = context {
                    return appName == "Web: \(urlHost)"
                }
                return false
            }
            
            if isDuplicate {
                continue
            }
            
            await MainActor.run {
                model.pendingContextList.append(.loading(urlHost))
            }
            
            do {
                let result = try await URLDetector.scrapeContentAndMetadata(from: url)
                
                await MainActor.run {
                    // Remove loading context
                    model.pendingContextList.removeAll { context in
                        if case .loading(let host) = context {
                            return host == urlHost
                        }
                        return false
                    }
                    
                    // Add web context with metadata
                    let webContext = Context.webAuto(
                        "Web: \(urlHost)",
                        ["content": result.content],
                        result.asWebMetadata
                    )
                    model.pendingContextList.append(webContext)
                }
            } catch {
                print("Error scraping content from URL: \(error)")
                await MainActor.run {
                    model.pendingContextList.removeAll { context in
                        if case .loading(let host) = context {
                            return host == urlHost
                        }
                        return false
                    }
                }
            }
        }
    }

    func sendAction() {
        let inputText = model.pendingInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add empty check
        guard !inputText.isEmpty else { return }
        
        // Final URL check before sending
        Task {
            await checkForURLs()
            await MainActor.run {
                model.createAndSavePrompt()
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
