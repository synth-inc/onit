//
//  InputField.swift
//  Onit
//
//  Created by Loyd Kim on 5/1/25.
//

import SwiftUI

struct InputField: View {
    // MARK: - Types

    struct ColorConfig {
        var background: Color = Color.T_9
        var border: Color = Color.genericBorder
    }
    
    struct SizeConfig {
        var height: CGFloat = 40
        var cornerRadius: CGFloat = 9
    }
    
    struct StatusConfig {
        var shouldFocusOnAppear: Bool = true
        var borderDotted: Bool = false
    }
    
    // MARK: - Properties
    
    @Binding var text: String
    let placeholder: String
    var errorMessage: String? = nil
    
    var colorConfig: ColorConfig = .init()
    var sizeConfig: SizeConfig = .init()
    var statusConfig: StatusConfig = .init()
    
    var onSubmit: (() -> Void)? = nil
    
    // MARK: - States
    
    @FocusState private var isFocused: Bool
    @State private var isHovered: Bool = false
    
    // MARK: - Private Variables
    
    private var hasError: Bool {
        if let errorMessage {
            return !errorMessage.isEmpty
        } else {
            return false
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 14)
                .frame(
                    height: sizeConfig.height,
                    alignment: .center
                )
                .styleText(
                    size: 14,
                    weight: .regular
                )
                .background(colorConfig.background.opacity(isHovered ? 0.7 : 1.0))
                .addBorder(
                    cornerRadius: sizeConfig.cornerRadius,
                    stroke: hasError ? Color.red500 : colorConfig.border,
                    dotted: statusConfig.borderDotted
                )
                .addAnimation(dependency: isHovered)
                .focused($isFocused)
                .onHover { isHovered in
                    self.isHovered = isHovered
                }
                .onAppear {
                    isFocused = statusConfig.shouldFocusOnAppear
                }
                .onSubmit {
                    onSubmit?()
                }
            
            if hasError,
               let errorMessage
            {
                Text(errorMessage)
                    .styleText(
                        size: 12,
                        weight: .regular,
                        color: Color.red500
                    )
                    .addAnimation(dependency: errorMessage)
            }
        }
    }
}
