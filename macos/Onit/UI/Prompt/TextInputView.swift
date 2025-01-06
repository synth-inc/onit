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

    @Query(sort: \Prompt.timestamp, order: .reverse) private var prompts: [Prompt]

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
        }
    }

    @ViewBuilder
    var textField: some View {
        @Bindable var model = model

        ZStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                TextField("", text: $model.instructions, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($focused)
                    .tint(.blue600.opacity(0.2))
                    .fixedSize(horizontal: false, vertical: true)
                if model.generationState == .generated {
                    Button("Edit") {
                        focused = true
                    }
                    .appFont(.medium16)
                    .foregroundStyle(.gray300)
                }
            }
            if model.instructions.isEmpty {
                placeholderView
            } else {
                Text(" ")
            }
        }
        .appFont(.medium16)
        .foregroundStyle(.white)
        .onAppear {
            focused = true
        }
        .onChange(of: model.textFocusTrigger) {
            focused = true
        }
    }

    var placeholderView: some View {
        HStack {
            Text("New instructions...")
            Image(.smirk)
                .renderingMode(.template)
        }
        .foregroundStyle(.gray300)
        .allowsHitTesting(false)
    }

    var sendButton: some View {
        Button {
            focused = false
            model.save(model.instructions)
            model.generate(model.instructions)
        } label: {
            Image(model.preferences.mode == .local ? .circleArrowUpDotted : .circleArrowUp)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(model.instructions.isEmpty ? Color.gray700 : (model.preferences.mode == .local ? .green : Color.blue400))
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        
        .disabled(model.instructions.isEmpty)
        .keyboardShortcut(.return, modifiers: [])
    }

    var upListener: some View {
        Button {
            guard !prompts.isEmpty else { return }

            if model.historyIndex + 1 < prompts.count {
                model.historyIndex += 1
                model.instructions = prompts[model.historyIndex].text
                model.input = prompts[model.historyIndex].input
                model.generationIndex = 0
                model.prompt = prompts[model.historyIndex]
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
                model.instructions = prompts[model.historyIndex].text
                model.input = prompts[model.historyIndex].input
                model.prompt = prompts[model.historyIndex]
            } else if model.historyIndex == 0 {
                model.historyIndex = -1
                model.instructions = ""
                model.input = nil
                model.prompt = nil
                focused = true
            }
            model.generationIndex = 0
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.downArrow, modifiers: [])
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
