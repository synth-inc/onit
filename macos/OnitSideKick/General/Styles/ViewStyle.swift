//
//  ViewStyle.swift
//  Onit
//
//  Created by Loyd Kim on 4/15/25.
//

import SwiftUI

// MARK: - Types

struct GradientBorder {
    var colorOne: Color = Color.genericBorder
    var colorTwo: Color = Color.genericBorder
}

struct DefaultBorderValues {
    var cornerRadius: CGFloat = 10
    var inset: CGFloat = 0.5
    var lineWidth: CGFloat = 1
}

struct BorderSides: OptionSet {
    let rawValue: Int

    static let top    = BorderSides(rawValue: 1 << 0)
    static let right  = BorderSides(rawValue: 1 << 1)
    static let bottom = BorderSides(rawValue: 1 << 2)
    static let left   = BorderSides(rawValue: 1 << 3)

    static let all: BorderSides = [.top, .right, .bottom, .left]
}

// MARK: - Partial Border View

private struct PartialBorder: View {
    let sides: BorderSides
    let lineWidth: CGFloat
    let stroke: Color
    let dash: [CGFloat]

    var body: some View {
        ZStack {
            if sides.contains(.top) {
                edge(.horizontal)
                    .frame(height: lineWidth)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            if sides.contains(.bottom) {
                edge(.horizontal)
                    .frame(height: lineWidth)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            if sides.contains(.left) {
                edge(.vertical)
                    .frame(width: lineWidth)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            if sides.contains(.right) {
                edge(.vertical)
                    .frame(width: lineWidth)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
        }
        .allowsHitTesting(false)
    }

    private func edge(_ axis: Axis) -> some View {
        BorderLine(axis: axis)
            .stroke(
                stroke,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    dash: dash
                )
            )
    }
    
    private struct BorderLine: Shape {
        let axis: Axis

        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            switch axis {
            case .vertical:
                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            case .horizontal:
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
            return path
        }
    }
}

extension View {
    // MARK: - Add Border

    @ViewBuilder
    func addBorder(
        sides: BorderSides = [],
        cornerRadius: CGFloat = DefaultBorderValues().cornerRadius,
        inset: CGFloat = DefaultBorderValues().inset,
        lineWidth: CGFloat = DefaultBorderValues().lineWidth,
        stroke: Color = Color.genericBorder,
        dotted: Bool = false,
        dottedDash: [CGFloat]? = nil
    ) -> some View {
        let dash: [CGFloat] = {
            guard dotted else { return [] }
            if let dottedDash { return dottedDash }
            return lineWidth >= 2 ? [2, 3] : [1, 2]
        }()
        if sides.isEmpty || sides == .all {
            self
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .inset(by: inset)
                        .stroke(
                            stroke,
                            style: StrokeStyle(
                                lineWidth: lineWidth,
                                dash: dash
                            )
                        )
                )
                .cornerRadius(cornerRadius)
        } else {
            self.overlay(
                PartialBorder(
                    sides: sides,
                    lineWidth: lineWidth,
                    stroke: stroke,
                    dash: dash
                )
            )
        }
    }
    
    // MARK: - Add Gradient Border
    
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
    
    // MARK: - Add Shadow
    
    func addShadow(
        color: Color = Color.S_0.opacity(0.8),
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
        fontFamily: FontFamily = FontFamily.system,
        size: CGFloat = 14,
        italic: Bool = false,
        weight: Font.Weight = Font.Weight.medium,
        color: Color = Color.S_0,
        align: TextAlignment = TextAlignment.leading,
        underline: Bool = false
    ) -> some View {
        self
            .font(fontFamily.font(size: size))
            .italic(italic)
            .fontWeight(weight)
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
        pointerStyle: HoverPointerStyle = HoverPointerStyle.link,
        background: Color = Color.clear,
        hoverBackground: Color = Color.T_8,
        cornerRadius: CGFloat = 8,
        disabled: Bool = false,
        shouldFadeOnDisabled: Bool = true,
        allowsHitTesting: Bool = true,
        shouldFadeOnClick: Bool = true,
        isHovered: Binding<Bool>,
        isPressed: Binding<Bool>,
        shadow: Color = Color.clear,
        tooltipPrompt: String? = nil,
        tooltipShortcut: Tooltip.Shortcut? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        self
            .background(isHovered.wrappedValue && allowsHitTesting ? hoverBackground : background)
            .cornerRadius(cornerRadius)
            .scaleEffect(isPressed.wrappedValue ? 0.99 : 1)
            .opacity(
                disabled && shouldFadeOnDisabled ? 0.4
                    : (isPressed.wrappedValue && shouldFadeOnClick) ? 0.7
                    : 1
            )
            .disabled(disabled)
            .contentShape(Rectangle())
            .onHover{ isHovering in
                isHovered.wrappedValue = isHovering
            }
            .modifier(BoundedDragActionModifier(isPressed: isPressed, action: action))
            .allowsHitTesting(allowsHitTesting)
            .shadow(color: shadow.opacity(0.05), radius: 0, x: 0, y: 0)
            .shadow(color: shadow.opacity(0.2), radius: 1.25, x: 0, y: 0.5)
            .addAnimation(
                dependency: [
                    isHovered.wrappedValue,
                    disabled
                ]
            )
            .onChange(of: isHovered.wrappedValue) { _, isHovering in
                TooltipHelpers.setTooltipOnHover(
                    isHovering: isHovering,
                    tooltipPrompt: tooltipPrompt,
                    tooltipShortcut: tooltipShortcut ?? .none
                )
            }
            .hoverPointerStyle(disabled ? nil : pointerStyle)
    }
}

/// Matches the cancel-on-drag-out behavior of `SwiftUI.Button`.
private struct BoundedDragActionModifier: ViewModifier {
    let isPressed: Binding<Bool>
    let action: (() -> Void)?

    @State private var size: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { size = geo.size }
                        .onChange(of: geo.size) { _, newSize in size = newSize }
                }
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed.wrappedValue = true }
                    .onEnded { value in
                        isPressed.wrappedValue = false
                        TooltipManager.shared.setTooltip(nil)
                        let bounds = CGRect(origin: .zero, size: size)
                        if bounds.contains(value.location) {
                            action?()
                        }
                    }
            )
    }
}
