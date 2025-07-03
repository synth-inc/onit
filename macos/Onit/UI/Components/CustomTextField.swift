//
//  CustomTextField.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import SwiftUI

struct CustomTextField: View {
    @Binding var text: String
    private let placeholder: String
    private let iconSize: CGFloat
    private let sidePadding: CGFloat
    
    struct Config {
        var background: Color = .clear
        var strokeColor: Color = .gray600
        var hoverStrokeColor: Color = .gray500
        var focusedStrokeColor: Color = .gray400
        var clear: Bool = false
        var leftIcon: ImageResource? = nil
    }
    private let config: Config
    
    init(
        text: Binding<String>,
        placeholder: String = "Search for...",
        sidePadding: CGFloat = 0,
        config: Config = Config(),
        iconSize: CGFloat = 18
    ) {
        self._text = text
        self.placeholder = placeholder
        self.sidePadding = sidePadding
        self.config = config
        self.iconSize = iconSize
    }
    
    @State private var textFieldHovered: Bool = false
    @State private var closeButtonHovered: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if let leftIcon = config.leftIcon {
                Image(leftIcon)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.gray200)
                    .frame(width: iconSize, height: iconSize)
            }
            
            ZStack(alignment: .leading) {
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .focused($focused)
                
                if text.isEmpty { placeholderView }
            }
            
            if config.clear && !text.isEmpty { clearButton }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .padding(.horizontal, 8)
        .background(config.background)
        .addBorder(
            cornerRadius: 8,
            stroke:
                textFieldHovered ? config.hoverStrokeColor :
                focused ? config.focusedStrokeColor :
                config.strokeColor
        )
        .addAnimation(dependency: $textFieldHovered.wrappedValue)
        .onHover{ isHovering in textFieldHovered = isHovering }
        .padding(.horizontal, sidePadding)
    }
}

// MARK: - Child Components

extension CustomTextField {
    private var placeholderView: some View {
        Text(placeholder)
            .styleText(color: .gray300)
            .allowsHitTesting(false)
    }
    
    private var clearButton: some View {
        Button {
            text = ""
        } label: {
            Image(.smallCross)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(closeButtonHovered ? .white : .gray200)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 18, height: 18)
        .animation(.easeIn(duration: AnimationStyle.animationDuration), value: $closeButtonHovered.wrappedValue)
        .onHover{ isHovering in closeButtonHovered = isHovering }
    }
}

// MARK: - Preview

#Preview {
    CustomTextField(text: .constant("fea"), placeholder: "Some title")
}
