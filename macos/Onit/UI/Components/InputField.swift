//
//  InputField.swift
//  Onit
//
//  Created by Loyd Kim on 5/1/25.
//

import SwiftUI

struct InputField: View {
    private let placeholder: String
    @Binding private var text: String
    private let errorMessage: String
    private let onSubmit: (() -> Void)?
    
    init(
        placeholder: String = "",
        text: Binding<String>,
        errorMessage: String = "",
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.errorMessage = errorMessage
        self.onSubmit = onSubmit
    }
    
    @FocusState private var isFocused: Bool
    @State private var isHovered: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .frame(height: 40)
                .styleText(size: 14)
                .padding(.horizontal, 14)
                .background(isHovered ? Color.T_8 : Color.T_9)
                .addBorder(
                    cornerRadius: 9,
                    stroke: errorMessage.isEmpty ? Color.genericBorder : Color.red500
                )
                .focused($isFocused)
                .onHover{ isHovering in isHovered = isHovering }
                .onAppear { isFocused = true }
                .onSubmit {
                    if let onSubmit = onSubmit { onSubmit() }
                }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .styleText(size: 12, weight: .medium, color: Color.red500)
                    .opacity(errorMessage.isEmpty ? 0 : 1)
                    .addAnimation(dependency: errorMessage)
            }
        }
    }
}
