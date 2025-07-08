//
//  ViewStyle.swift
//  Onit
//
//  Created by Loyd Kim on 4/15/25.
//

import SwiftUI

// MARK: - General View Styles

struct GradientBorder {
    var colorOne: Color = Color.white
    var colorTwo: Color = Color.white
}

struct DefaultBorderValues {
    var cornerRadius: CGFloat = 12
    var inset: CGFloat = 0.5
    var lineWidth: CGFloat = 1
}

extension View {
    func addBorder(
        cornerRadius: CGFloat = DefaultBorderValues().cornerRadius,
        inset: CGFloat = DefaultBorderValues().inset,
        lineWidth: CGFloat = DefaultBorderValues().lineWidth,
        stroke: Color = Color.gray500,
        dotted: Bool = false
    ) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .inset(by: inset)
                    .stroke(
                        stroke,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            dash: dotted ? [2, 2] : []
                        )
                    )
            )
            .cornerRadius(cornerRadius)
    }
    
    func addGradientBorder(
        cornerRadius: CGFloat = DefaultBorderValues().cornerRadius,
        inset: CGFloat = DefaultBorderValues().inset,
        lineWidth: CGFloat = DefaultBorderValues().lineWidth,
        gradientBorder: GradientBorder = GradientBorder()
    ) -> some View {
        self
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .inset(by: inset)
                    .stroke(
                        LinearGradient(
                            gradient:
                                Gradient(colors: [
                                    gradientBorder.colorOne,
                                    gradientBorder.colorTwo
                                ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth
                    )
            )
    }
    
    func addShadow(
        color: Color = Color.black.opacity(0.8),
        radius: CGFloat = 5.5,
        x: CGFloat = 0,
        y: CGFloat = 2
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
}

// MARK: - Text Styles

extension View {
    func styleText(
        size: CGFloat = 14,
        weight: Font.Weight = Font.Weight.medium,
        color: Color = Color.primary,
        align: TextAlignment = TextAlignment.leading,
        underline: Bool = false
    ) -> some View {
        self
            .font(.system(
                size: size, weight: weight
            ))
            .foregroundColor(color)
            .multilineTextAlignment(align)
            .underline(underline)
    }
    
    func truncateText(lineLimit: Int = 1) -> some View {
        self.lineLimit(lineLimit).truncationMode(.tail)
    }
}

// MARK: - Button Styles

extension View {
    func addButtonEffects(
        background: Color = .clear,
        hoverBackground: Color = .gray600,
        cornerRadius: CGFloat = 8,
        disabled: Bool = false,
        allowsHitTesting: Bool = true,
        shouldFadeOnClick: Bool = true,
        isHovered: Binding<Bool>,
        isPressed: Binding<Bool>,
        action: (() -> Void)?
    ) -> some View {
        self
            .background(isHovered.wrappedValue ? hoverBackground : background)
            .cornerRadius(cornerRadius)
            .scaleEffect(isPressed.wrappedValue ? 0.99 : 1)
            .opacity(
                disabled ? 0.4
                    : (isPressed.wrappedValue && shouldFadeOnClick) ? 0.7
                    : 1
            )
            .disabled(disabled)
            .onHover{ isHovering in
                isHovered.wrappedValue = isHovering
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged {_ in isPressed.wrappedValue = true }
                    .onEnded{ _ in
                        isPressed.wrappedValue = false
                        action?()
                    }
                )
            .allowsHitTesting(allowsHitTesting)
            .addAnimation(
                dependency: [
                    isHovered.wrappedValue,
                    disabled
                ]
            )
    }
}
