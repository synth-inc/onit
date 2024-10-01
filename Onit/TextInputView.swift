//
//  PreferencesView.swift
//  Omni
//
//  Created by Benjamin Sage on 9/17/24.
//

import SwiftUI

struct TextInputView: View {
    @State private var instructions = ""

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
            .foregroundStyle(.white)
            .tint(.foreground)
            .appFont(.medium16)
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
        Image(.circleArrowUp)
            .renderingMode(.template)
            .foregroundStyle(instructions.isEmpty ? Color.gray700 : .blue400)
            .padding(3)
    }
}

#Preview {
    TextInputView()
}
