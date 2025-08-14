//
//  FinalContextView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import Defaults
import SwiftUI

struct FinalContextView: View {
    @Environment(\.appState) var appState
    @Environment(\.windowState) var windowState
    
    @State var isExpanded: Bool = false
    @State private var isEditing: Bool = false
    @State private var isHoveringInstruction: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var cursorPosition: Int = 0
    @State private var textHeight: CGFloat = 20
    private let maxHeightLimit: CGFloat = 100
    @StateObject private var audioRecorder = AudioRecorder()

    let prompt: Prompt

    var usingContextOrInput: Bool {
        usingContext || prompt.input != nil
    }

    var usingContext: Bool {
        !prompt.contextList.isEmpty
    }

    var body: some View {
        
        @Default(.lineHeight) var lineHeight
        @Default(.fontSize) var fontSize
        
        VStack(alignment: .leading, spacing: 8) {
            VStack {
                TextViewWrapper(
                    text: Binding(
                        get: { prompt.instruction },
                        set: {
                            prompt.instruction = $0
                            windowState?.detectIsTyping()
                        }
                    ),
                    cursorPosition: $cursorPosition,
                    dynamicHeight: $textHeight,
                    onSubmit: {
                        if isEditing {
                            isEditing = false
                            
                            Task {
                                await handleSend()
                            }
                        }
                    },
                    maxHeight: maxHeightLimit,
                    placeholder: "",
                    audioRecorder: audioRecorder,
                    detectLinks: false
                )
                .frame(height: min(textHeight, maxHeightLimit))
                .allowsHitTesting(isEditing)
                .textSelection(.enabled)
                .focused($isTextFieldFocused)
                .foregroundColor(Color.S_0)
                .scrollContentBackground(.hidden)
                .padding(0) // To match the TextField padding
                .onChange(of: cursorPosition) {
                    windowState?.detectIsTyping()
                }

                if isEditing {
                    HStack {
                        Spacer()
                        Button("Cancel") {
                            isEditing = false
                            windowState?.textFocusTrigger.toggle()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.S_4)
                        .foregroundColor(Color.S_0)
                        .cornerRadius(8)

                        Button("Send") {
                            // Handle send action
                            isEditing = false
                            
                            Task {
                                await handleSend()
                            }
                            
                            windowState?.textFocusTrigger.toggle()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.blue400)
                        .foregroundColor(Color.white)
                        .cornerRadius(8)
                        .keyboardShortcut(.return, modifiers: [])
                    }
                    .padding(.trailing, 8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(Color.messageBG, in: .rect(cornerRadius: 10))
            .addBorder()
            .contentShape(Rectangle()) // Make the entire VStack tappable
            .onTapGesture {
                isEditing = true
                isTextFieldFocused = true
            }
            .overlay(alignment: .topTrailing) {
                Image(.edit)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 16, height: 16)
                    .padding(4)
                    .background(Color.T_5)
                    .foregroundColor(Color.S_0)
                    .cornerRadius(6)
                    .opacity(isHoveringInstruction && !isEditing ? 1 : 0) // Initially hidden
                    .offset(x: -8, y: 6) // 6 pixels down from the top edge and 8 pixels in from the right edge
                    .allowsHitTesting(false)
            }
            .onHover { hovering in
                isHoveringInstruction = hovering
            }
            
            if windowState?.isSearchingWeb[prompt.id] ?? false {
                HStack {
                    Image(.web)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .padding(4)
                        .foregroundColor(Color.S_2)
                    Text("Searching the web")
                        .appFont(.medium16)
                        .foregroundColor(Color.S_2)
                    Spacer()
                }
                .shimmering()
            } else if usingContextOrInput {
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack(alignment: .center) {
                        Image(.paperclip)
                            .addIconStyles(
                                foregroundColor: Color.S_2,
                                iconSize: 16
                            )
                        Text("Final context used")
                            .appFont(.medium13)
                        Image(.smallChevDown)
                            .renderingMode(.template)
                            .rotationEffect(isExpanded ? .degrees(180) : .degrees(0))
                            .foregroundColor(Color.S_3)
                        Spacer()
                    }
                }
                .foregroundStyle(Color.S_2)
                .buttonStyle(.plain)

                if isExpanded {
                    if let input = prompt.input {
                        InputView(input: input, isEditing: false)
                    }

                    if usingContext {
                        ContextList(contextList: prompt.contextList, direction: .vertical, onItemTap: { context in
                            if context.isWebSearchContext, let url = context.webURL {
                                NSWorkspace.shared.open(url)
                            } else {
                                if let windowState = windowState {
                                    ContextWindowsManager.shared.showContextWindow(windowState: windowState, context: context)
                                }
                            }
                        })
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.clear)
                                    .strokeBorder(Color.genericBorder)
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Private Functions

extension FinalContextView {
    private func handleSend() async {
        await appState.checkSubscriptionAlerts {
            windowState?.generate(prompt)
        }
    }
}

#Preview {
    FinalContextView(isExpanded: true, prompt: .sample)
}
