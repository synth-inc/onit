//
//  PreferencesView.swift
//  Omni
//
//  Created by Benjamin Sage on 9/17/24.
//

import SwiftUI

struct TextInputView: View {
    @Environment(\.model) var model

    @State private var instructions = ""
    @FocusState var focused: Bool

    var body: some View {
        HStack {
            textField
            sendButton
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    var textField: some View {
        ZStack(alignment: .leading) {
            TextField("", text: $instructions, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($focused)
                .tint(.blue600.opacity(0.2))
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
            model.generate(instructions)
        } label: {
            Image(.circleArrowUp)
                .renderingMode(.template)
                .foregroundStyle(instructions.isEmpty ? Color.gray700 : .blue400)
                .padding(3)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.return, modifiers: [])
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
