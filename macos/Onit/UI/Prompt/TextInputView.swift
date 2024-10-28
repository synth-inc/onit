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

    @AppStorage("instructions") private var instructions = ""
    @FocusState var focused: Bool

    @Query(sort: \Prompt.timestamp, order: .reverse) private var prompts: [Prompt]

    @State private var historyIndex = -1

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

    var textField: some View {
        ZStack(alignment: .leading) {
            TextField("", text: $instructions, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($focused)
                .tint(.blue600.opacity(0.2))
                .fixedSize(horizontal: false, vertical: true)
            if instructions.isEmpty {
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
            model.save(instructions)
            model.generate(instructions)
        } label: {
            Image(.circleArrowUp)
                .renderingMode(.template)
                .foregroundStyle(instructions.isEmpty ? Color.gray700 : .blue400)
                .padding(3)
        }
        .buttonStyle(.plain)
        .disabled(instructions.isEmpty)
        .keyboardShortcut(.return, modifiers: [])
    }

    var upListener: some View {
        Button {
            guard !prompts.isEmpty else { return }

            if historyIndex + 1 < prompts.count {
                historyIndex += 1
                instructions = prompts[historyIndex].text
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.upArrow, modifiers: [])
    }

    var downListener: some View {
        Button {
            if historyIndex > 0 {
                historyIndex -= 1
                instructions = prompts[historyIndex].text
            } else if historyIndex == 0 {
                historyIndex = -1
                instructions = ""
            }
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
