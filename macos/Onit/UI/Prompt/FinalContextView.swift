//
//  FinalContextView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import Defaults
import SwiftUI

struct FinalContextView: View {
    @Environment(\.model) var model
    @State var isExpanded: Bool = true
    @State private var isEditing: Bool = false
    @State private var isHoveringInstruction: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
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
        
        
        VStack(alignment: .leading, spacing: 12) {
            if usingContextOrInput {
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack(alignment: .center) {
                        Image(.paperclipStars)
                        Text("Final context used")
                            .appFont(.medium14)
                        Image(.smallChevDown)
                            .renderingMode(.template)
                            .rotationEffect(isExpanded ? .degrees(180) : .degrees(0))
                        Spacer()
                    }
                }
                .foregroundStyle(.gray100)
                .buttonStyle(.plain)

                if isExpanded {
                    if let input = prompt.input {
                        InputView(input: input, isEditing: false)
                    }

                    if usingContext {
                        ContextList(contextList: prompt.contextList, direction: .vertical)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.clear)
                                    .strokeBorder(.gray700)
                            }
                    }
                }
            }

            VStack {
                TextViewWrapper(
                    text: Binding(
                        get: { prompt.instruction },
                        set: { prompt.instruction = $0 }
                    ),
                    cursorPosition: .constant(prompt.instruction.count),
                    dynamicHeight: $textHeight,
                    onSubmit: {
                        if isEditing {
                            isEditing = false
                            model.generate(prompt)
                        }
                    },
                    maxHeight: maxHeightLimit,
                    placeholder: "",
                    audioRecorder: audioRecorder,
                    detectLinks: false
                )
                .appFont(.medium16)
                .frame(height: min(textHeight, maxHeightLimit))
                .allowsHitTesting(isEditing)
                .textSelection(.enabled)
                .focused($isTextFieldFocused)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(.gray800) // To match the TextField style
                .padding(0) // To match the TextField padding

                if isEditing {
                    HStack {
                        Spacer()
                        Button("Cancel") {
                            isEditing = false
                            model.textFocusTrigger.toggle()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.gray500)
                        .foregroundColor(.white)
                        .cornerRadius(8)

                        Button("Send") {
                            // Handle send action
                            isEditing = false
                            model.generate(prompt)
                            model.textFocusTrigger.toggle()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.blue400)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .keyboardShortcut(.return, modifiers: [])
                    }
                    .padding(.trailing, 8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(.gray800, in: .rect(cornerRadius: 8))
            .contentShape(Rectangle()) // Make the entire VStack tappable
            .onTapGesture {
                isEditing = true
                isTextFieldFocused = true
            }
            .overlay(alignment: .topTrailing) {
                Image(.edit)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(4)
                    .background(.gray500)
                    .foregroundColor(.gray200)
                    .cornerRadius(6)
                    .opacity(isHoveringInstruction && !isEditing ? 1 : 0) // Initially hidden
                    .offset(x: -8, y: 6) // 6 pixels down from the top edge and 8 pixels in from the right edge
                    .allowsHitTesting(false)
            }
            .onHover { hovering in
                isHoveringInstruction = hovering
            }
        }
        .padding()
    }
}

#Preview {
    FinalContextView(isExpanded: true, prompt: .sample)
}
