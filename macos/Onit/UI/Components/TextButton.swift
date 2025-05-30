//
//  TextButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/14/25.
//

import SwiftUI

struct TextButton<Child: View>: View {
    private let iconSize: CGFloat
    private let iconColor: Color
    private let disabled: Bool
    private let selected: Bool
    
    private let gap: CGFloat
    private let maxWidth: CGFloat
    private let height: CGFloat
    private let fillContainer: Bool
    private let horizontalPadding: CGFloat
    private let cornerRadius: CGFloat
    
    private let background: Color
    private let hoverBackground: Color
    private let fontSize: CGFloat
    private let fontWeight: Font.Weight
    private let fontColor: Color
    
    private let icon: ImageResource?
    private let text: String?
    private let width: CGFloat?
    
    @ViewBuilder private let child: () -> Child
    private let action: () -> Void
    
    init(
        iconSize: CGFloat = 20,
        iconColor: Color = .white,
        disabled: Bool = false,
        selected: Bool = false,

        gap: CGFloat = 10,
        maxWidth: CGFloat = 0,
        height: CGFloat = 32,
        fillContainer: Bool = true,
        horizontalPadding: CGFloat = 8,
        cornerRadius: CGFloat = 8,

        background: Color = .clear,
        hoverBackground: Color = .gray600,
        fontSize: CGFloat = 14,
        fontWeight: Font.Weight = Font.Weight.medium,
        fontColor: Color = Color.white,

        icon: ImageResource? = nil,
        text: String? = nil,
        width: CGFloat? = nil,
        
        @ViewBuilder child: @escaping () -> Child = { EmptyView() },
        action: @escaping () -> Void
    ) {
        self.iconSize = iconSize
        self.iconColor = iconColor
        self.disabled = disabled
        self.selected = selected
        
        self.gap = gap
        self.maxWidth = maxWidth
        self.height = height
        self.fillContainer = fillContainer
        self.horizontalPadding = horizontalPadding
        self.cornerRadius = cornerRadius
        
        self.background = background
        self.hoverBackground = hoverBackground
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontColor = fontColor
        
        self.icon = icon
        self.text = text
        self.width = width
        
        self.child = child
        self.action = action
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: gap) {
            if let icon = icon {
                Image(icon).addIconStyles(
                    foregroundColor: selected ? .blue300 : iconColor,
                    iconSize: iconSize
                )
            }
            
            if let text = text {
                Text(text)
                    .styleText(
                        size: fontSize,
                        weight: fontWeight,
                        color: disabled ? .gray200 : selected ? .blue300 : isHovered ? .white : fontColor
                    )
                    .truncateText()
            }
            
            if fillContainer { Spacer() }
            
            child()
        }
        .padding(.horizontal, horizontalPadding)
        .frame(width: width ?? nil)
        .frame(maxWidth: fillContainer ? .infinity : maxWidth > 0 ? maxWidth : nil)
        .frame(height: height)
        .onHover{ isHovering in isHovered = isHovering }
        .addButtonEffects(
            background: disabled ? .clear : background,
            hoverBackground: disabled ? .clear : hoverBackground,
            cornerRadius: cornerRadius,
            disabled: disabled,
            allowsHitTesting: !selected,
            isHovered: $isHovered,
            isPressed: $isPressed,
            action: action
        )
    }
}
