//
//  SimpleButton.swift
//  Onit
//
//  Created by Loyd Kim on 5/5/25.
//

import SwiftUI

struct SimpleButton: View {
    let iconText: String?
    let iconImage: ImageResource?
    let iconImageSize: CGFloat
    let iconImageColor: Color
    let iconSystem: String?
    let iconColor: Color
    let isLoading: Bool
    let disabled: Bool
    let spacing: CGFloat
    let text: String
    let textColor: Color
    let textWeight: Font.Weight
    let cornerRadius: CGFloat
    let action: () -> Void
    let background: Color
    let hoverBackground: Color?
    let fillContainer: Bool
    let alignment: Alignment
    let paddingHorizontal: CGFloat
    
    init(
        iconText: String? = nil,
        iconImage: ImageResource? = nil,
        iconImageSize: CGFloat = 20,
        iconImageColor: Color = Color.S_0,
        iconSystem: String? = nil,
        iconColor: Color = Color.S_0,
        isLoading: Bool = false,
        disabled: Bool = false,
        spacing: CGFloat = 4,
        text: String,
        textColor: Color = Color.S_0,
        textWeight: Font.Weight = .light,
        cornerRadius: CGFloat = 5,
        action: @escaping () -> Void,
        background: Color = Color.S_4,
        hoverBackground: Color? = nil,
        fillContainer: Bool = false,
        alignment: Alignment = .center,
        paddingHorizontal: CGFloat = 7
    ) {
        self.iconText = iconText
        self.iconImage = iconImage
        self.iconImageSize = iconImageSize
        self.iconImageColor = iconImageColor
        self.iconSystem = iconSystem
        self.iconColor = iconColor
        self.isLoading = isLoading
        self.disabled = disabled
        self.spacing = spacing
        self.text = text
        self.textColor = textColor
        self.textWeight = textWeight
        self.cornerRadius = cornerRadius
        self.action = action
        self.background = background
        self.hoverBackground = hoverBackground
        self.fillContainer = fillContainer
        self.alignment = alignment
        self.paddingHorizontal = paddingHorizontal
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    private var allowsHitTesting: Bool {
        !isLoading && !disabled
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            if isLoading {
                Loader()
            } else if let iconText = iconText {
                Text(iconText).styleText(size: 12)
            } else if let iconSystem = iconSystem {
                Image(systemName: iconSystem)
                    .foregroundStyle(iconColor)
            } else if let iconImage = iconImage {
                Image(iconImage)
                    .addIconStyles(
                        foregroundColor: self.iconImageColor,
                        iconSize: self.iconImageSize
                    )
            }
            
            Text(text).styleText(size: 13, weight: self.textWeight, color: textColor)
        }
        .padding(.horizontal, paddingHorizontal)
        .padding(.vertical, 3)
        .frame(maxWidth: self.fillContainer ? .infinity : nil, alignment: self.alignment)
        .addButtonEffects(
            background: background,
            hoverBackground: hoverBackground ?? background.opacity(0.7),
            cornerRadius: self.cornerRadius,
            disabled: !allowsHitTesting,
            allowsHitTesting: allowsHitTesting,
            isHovered: $isHovered,
            isPressed: $isPressed,
            shadow: background
        ) {
            action()
        }
        .onHover { isHovering in isHovered = isHovering}
    }
}
