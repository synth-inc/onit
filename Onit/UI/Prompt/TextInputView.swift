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
        TextField("", text: $instructions, axis: .vertical)
            .textFieldStyle(PlainTextFieldStyle())
            .overlay(alignment: .leading) {
                if instructions.isEmpty {
                    placeholderView
                }
            }
            .focused($focused)
            .foregroundStyle(.white)
            .tint(.FG)
            .appFont(.medium16)
            .onAppear {
                focused = true
            }
    }

    var placeholderView: some View {
        HStack {
            Text("New instructions...")
            Image("Smirk Icon")
        }
        .foregroundStyle(.gray300)
        .allowsHitTesting(false)
    }

    var sendButton: some View {
        Button {
            model.generate()
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