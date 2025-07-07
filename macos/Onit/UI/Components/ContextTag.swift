//
//  ContextTag.swift
//  Onit
//
//  Created by Loyd Kim on 5/28/25.
//

import SwiftUI

struct ContextTag: View {
    private let text: String
    private let textColor: Color
    private let hoverTextColor: Color
    private let background: Color
    private let hoverBackground: Color
    private let borderColor: Color
    private let hoverBorderColor: Color
    private let hasDottedBorder: Bool
    private let maxWidth: CGFloat
    private let isLoading: Bool
    private let shouldFadeIn: Bool
    private let showIndicator: Bool
    private let indicatorOffset: CGFloat
    private let iconBundleURL: URL?
    private let iconView: (any View)?
    private let caption: String?
    private let tooltip: String?
    private let errorDotColor: Color?
    private let action: (() -> Void)?
    private let pinAction: (() -> Void)?
    private let removeAction: (() -> Void)?
    
    init(
        text: String,
        textColor: Color = .T_2,
        hoverTextColor: Color = .white,
        background: Color = .gray500,
        hoverBackground: Color = .gray400,
        borderColor: Color = .clear,
        hoverBorderColor: Color = .clear,
        hasDottedBorder: Bool = false,
        maxWidth: CGFloat = 190,
        isLoading: Bool = false,
        shouldFadeIn: Bool = false,
        showIndicator: Bool = false,
        indicatorOffset: CGFloat = 0,
        iconBundleURL: URL? = nil,
        iconView: (any View)? = nil,
        caption: String? = nil,
        tooltip: String? = nil,
        errorDotColor: Color? = nil,
        action: (() -> Void)? = nil,
        pinAction: (() -> Void)? = nil,
        removeAction: (() -> Void)? = nil
    ) {
        self.text = text
        self.textColor = textColor
        self.hoverTextColor = hoverTextColor
        self.background = background
        self.hoverBackground = hoverBackground
        self.borderColor = borderColor
        self.hoverBorderColor = hoverBorderColor
        self.hasDottedBorder = hasDottedBorder
        self.maxWidth = maxWidth
        self.isLoading = isLoading
        self.shouldFadeIn = shouldFadeIn
        self.showIndicator = showIndicator
        self.indicatorOffset = indicatorOffset
        self.iconBundleURL = iconBundleURL
        self.iconView = iconView
        self.caption = caption
        self.tooltip = tooltip
        self.errorDotColor = errorDotColor
        self.action = action
        self.pinAction = pinAction
        self.removeAction = removeAction
    }
    
    @State private var isHoveredBody: Bool = false
    @State private var isPressedBody: Bool = false
    @State private var isHoveredPin: Bool = false
    @State private var isHoveredRemove: Bool = false
    
    private let height: CGFloat = 24
    private let tooltipMaxWidth: CGFloat = 200
    
    private var hasHoverAction: Bool {
        pinAction != nil || removeAction != nil
    }
    
    private var isHoveredActionButton: Bool {
        isHoveredRemove || isHoveredPin
    }
    
    private var hasIcon: Bool {
        bundleUrlIcon != nil || iconView != nil
    }
    
    private var bundleUrlIcon: NSImage? {
        guard let bundleUrl = iconBundleURL else { return nil }
        return NSWorkspace.shared.icon(forFile: bundleUrl.path)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 6) {
                if hasIcon {
                    ZStack(alignment: .bottomTrailing) {
                        if let bundleUrlIcon = bundleUrlIcon {
                            Image(nsImage: bundleUrlIcon)
                                .resizable()
                                .frame(width: 16, height: 16)
                                .cornerRadius(4)
                        }
                        
                        if let iconView = iconView {
                            AnyView(iconView)
                        }
                        
                        if let errorDotColor = errorDotColor {
                            Circle()
                                .fill(isHoveredBody ? hoverBackground : background)
                                .frame(width: 11, height: 11)
                                .overlay(
                                    Circle()
                                        .fill(errorDotColor.opacity(1.0))
                                        .frame(width: 7, height: 7)
                                )
                                .offset(x: 2, y: 2)
                        } else if showIndicator {
                            circleIndicator
                        }
                    }
                }
                
                if isLoading { textView.shimmering() }
                else { textView }
                
                if let caption = caption {
                    Text(caption)
                        .styleText(
                            size: 12,
                            weight: .regular,
                            color: .gray100
                        )
                        .truncateText()
                }
            }
            
            if hasHoverAction {
                HStack(spacing: 0) {
                    Spacer()
                    
                    FadeHorizontal(color: hoverBackground)
                    
                    HStack(alignment: .center, spacing: 8) {
                        if let pinAction = pinAction {
                            pinButton(pinAction)
                        }
                        
                        if let removeAction = removeAction {
                            removeButton(removeAction)
                        }
                    }
                    .background(hoverBackground)
                }
                .frame(height: height)
                .opacity(isHoveredBody ? 1 : 0)
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 6)
        .frame(height: height)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .opacity(shouldFadeIn ? isHoveredBody ? 1 : 0.7 : 1)
        .onHover { isHovering in
            isHoveredBody = isHovering
            
            if tooltip != nil {
                if isHovering {
                    TooltipManager.shared.setTooltip(
                        Tooltip(prompt: tooltip ?? ""),
                        maxWidth: tooltipMaxWidth,
                        delayStart: 0.4,
                        delayEnd: 0
                    )
                } else {
                    TooltipManager.shared.setTooltip(
                        nil,
                        maxWidth: tooltipMaxWidth,
                        delayEnd: 0
                    )
                }
            }
        }
        .addBorder(
            cornerRadius: 4,
            stroke: isHoveredBody ? hoverBorderColor : borderColor,
            dotted: hasDottedBorder
        )
        .addButtonEffects(
            background: background,
            hoverBackground: hoverBackground,
            cornerRadius: 4,
            shouldFadeOnClick: false,
            animationDuration: 0,
            isHovered: $isHoveredBody,
            isPressed: $isPressedBody,
            action: action
        )
    }
}

// MARK: - Child Components

extension ContextTag {
    private var circleIndicator: some View {
        ZStack {
            Circle()
                .fill(isHoveredBody ? hoverBackground : background)
                .frame(width: 10, height: 10)
            
            Circle()
                .stroke(.blue300, lineWidth: 2)
                .frame(width: 5, height: 5)
        }
        .offset(x: indicatorOffset, y: indicatorOffset)
    }
    
    private var textView: some View {
        Text(text)
            .styleText(
                size: 12,
                color: isHoveredActionButton ? .T_3 : isHoveredBody ? hoverTextColor : textColor
            )
            .truncateText()
            .addAnimation(dependency: [isHoveredBody, isHoveredRemove])
    }
    
    private func actionButton(
        icon: ImageResource,
        iconSize: CGFloat,
        action: @escaping () -> Void,
        isHovered: Binding<Bool>
    ) -> some View {
        Button {
            action()
        } label: {
            Image(icon)
                .addIconStyles(
                    foregroundColor: isHovered.wrappedValue ? .white : .gray100,
                    iconSize: iconSize
                )
                .addAnimation(dependency: isHovered.wrappedValue)
        }
        .onHover { isHovering in
            isHovered.wrappedValue = isHovering
        }
    }
    
    private func pinButton(_ pinAction: @escaping () -> Void) -> some View {
        actionButton(
            icon: .pin,
            iconSize: 12,
            action: pinAction,
            isHovered: $isHoveredPin
        )
    }
    
    private func removeButton(_ removeAction: @escaping () -> Void) -> some View {
        actionButton(
            icon: .cross,
            iconSize: 9,
            action: removeAction,
            isHovered: $isHoveredRemove
        )
    }
}
