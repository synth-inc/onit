//
//  TextButton.swift
//  Onit
//
//  Created by - on 4/14/25.
//

import SwiftUI

struct TextButton<Child: View>: View {
    private let icon: ImageResource?
    private let iconSize: CGFloat
    private let text: String
    private let disabled: Bool
    private let action: () -> Void
    
    private let gap: CGFloat
    private let width: CGFloat?
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
    
    @ViewBuilder private let child: () -> Child
    
    private struct DefaultValues {
        var iconSize: CGFloat = 20
        var disabled: Bool = false
        
        var gap: CGFloat = 10
        var width: CGFloat? = nil
        var maxWidth: CGFloat = 0
        var height: CGFloat = 32
        var fillContainer: Bool = true
        var horizontalPadding: CGFloat = 8
        var cornerRadius: CGFloat = 8
        
        var background: Color = .clear
        var hoverBackground: Color = .gray600
        var fontSize: CGFloat = 14
        var fontWeight: Font.Weight = Font.Weight.medium
        var fontColor: Color = Color.white
    }
    
    init(
        icon: ImageResource? = nil,
        iconSize: CGFloat = DefaultValues().iconSize,
        text: String,
        disabled: Bool = DefaultValues().disabled,
        action: @escaping () -> Void,
        
        gap: CGFloat = DefaultValues().gap,
        width: CGFloat? = DefaultValues().width,
        maxWidth: CGFloat = DefaultValues().maxWidth,
        height: CGFloat = DefaultValues().height,
        fillContainer: Bool = DefaultValues().fillContainer,
        horizontalPadding: CGFloat = DefaultValues().horizontalPadding,
        cornerRadius: CGFloat = DefaultValues().cornerRadius,
        
        background: Color = DefaultValues().background,
        hoverBackground: Color = DefaultValues().hoverBackground,
        fontSize: CGFloat = DefaultValues().fontSize,
        fontWeight: Font.Weight = DefaultValues().fontWeight,
        fontColor: Color = DefaultValues().fontColor,
        
        @ViewBuilder child: @escaping () -> Child
    ) {
        self.icon = icon
        self.iconSize = iconSize
        self.text = text
        self.disabled = disabled
        self.action = action
        
        self.gap = gap
        self.width = width
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
        
        self.child = child
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: gap) {
            if let icon = icon {
                Image(icon).addIconStyles(iconSize: iconSize)
            }
            
            Text(text)
                .styleText(
                    size: fontSize,
                    weight: fontWeight,
                    color: disabled ? .gray200 : isHovered ? .white : fontColor
                )
                .truncateText()
            
            if fillContainer { Spacer() }
            
            child()
        }
        .padding(.horizontal, horizontalPadding)
        .frame(width: width ?? nil)
        .frame(maxWidth: fillContainer ? .infinity : maxWidth > 0 ? maxWidth : nil)
        .frame(height: height)
        .background(disabled ? .clear : isHovered ? hoverBackground : background)
        .scaleEffect(isPressed ? 0.99 : 1)
        .opacity(disabled ? 0.5 : isPressed ? 0.7 : 1)
        .disabled(disabled)
        .cornerRadius(cornerRadius)
        .addAnimation(dependency: $isHovered.wrappedValue)
        .addAnimation(dependency: disabled)
        .onHover{ isHovering in isHovered = isHovering }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged {_ in isPressed = true }
                .onEnded{ _ in
                    isPressed = false
                    action()
                }
        )
    }
}

// MARK: - Allows `child` prop to be optional.

extension TextButton where Child == EmptyView {
    init(
        icon: ImageResource? = nil,
        iconSize: CGFloat = DefaultValues().iconSize,
        text: String,
        disabled: Bool = DefaultValues().disabled,
        action: @escaping () -> Void,
        
        gap: CGFloat = DefaultValues().gap,
        width: CGFloat? = DefaultValues().width,
        maxWidth: CGFloat = DefaultValues().maxWidth,
        height: CGFloat = DefaultValues().height,
        fillContainer: Bool = DefaultValues().fillContainer,
        horizontalPadding: CGFloat = DefaultValues().horizontalPadding,
        cornerRadius: CGFloat = DefaultValues().cornerRadius,
        
        background: Color = DefaultValues().background,
        hoverBackground: Color = DefaultValues().hoverBackground,
        fontSize: CGFloat = DefaultValues().fontSize,
        fontWeight: Font.Weight = DefaultValues().fontWeight,
        fontColor: Color = DefaultValues().fontColor
    ) {
        self.init(
            icon: icon,
            iconSize: iconSize,
            text: text,
            disabled: disabled,
            action: action,
            
            gap: gap,
            width: width,
            maxWidth: maxWidth,
            height: height,
            fillContainer: fillContainer,
            horizontalPadding: horizontalPadding,
            cornerRadius: cornerRadius,
            
            background: background,
            hoverBackground: hoverBackground,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontColor: fontColor
        ) {
            EmptyView()
        }
    }
}
