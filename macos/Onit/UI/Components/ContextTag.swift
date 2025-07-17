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
    private let hasHoverBorder: Bool
    private let maxWidth: CGFloat
    private let isLoading: Bool
    private let shouldFadeIn: Bool
    private let iconBundleURL: URL?
    private let iconView: (any View)?
    private let iconViewCornerIcon: ImageResource?
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
        hasHoverBorder: Bool = false,
        maxWidth: CGFloat = 155,
        isLoading: Bool = false,
        shouldFadeIn: Bool = false,
        iconBundleURL: URL? = nil,
        iconView: (any View)? = nil,
        iconViewCornerIcon: ImageResource? = nil,
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
        self.hasHoverBorder = hasHoverBorder
        self.maxWidth = maxWidth
        self.isLoading = isLoading
        self.shouldFadeIn = shouldFadeIn
        self.iconBundleURL = iconBundleURL
        self.iconView = iconView
        self.iconViewCornerIcon = iconViewCornerIcon
        self.caption = caption
        self.tooltip = tooltip
        self.errorDotColor = errorDotColor
        self.action = action
        self.pinAction = pinAction
        self.removeAction = removeAction
    }
    
    @State private var isHoveredBody: Bool = false
    @State private var isPressedBody: Bool = false
    @State private var isHoveredRemove: Bool = false
    
    private let height: CGFloat = 24
    
    private var bundleUrlIcon: NSImage? {
        guard let bundleUrl = iconBundleURL else { return nil }
        return NSWorkspace.shared.icon(forFile: bundleUrl.path)
    }
    
    private var hasHoverActions: Bool {
        pinAction != nil || removeAction != nil
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 6) {
                if let bundleUrlIcon = bundleUrlIcon {
                    ZStack(alignment: .bottomTrailing) {
                        Image(nsImage: bundleUrlIcon)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .cornerRadius(4)
                        
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
                        }
                    }
                }
                
                if let iconView = iconView {
                    ZStack(alignment: .bottomTrailing) {
                        AnyView(iconView)
                        
                        if let cornerIcon = iconViewCornerIcon {
                            ZStack(alignment: .center) {
                                Circle()
                                    .fill(isHoveredBody ? hoverBackground : background)
                                    .frame(width: 13, height: 13)
                                
                                Image(cornerIcon)
                                    .addIconStyles(iconSize: 7.45)
                            }
                            .offset(x: 4, y: 4)
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
            
            if hasHoverActions {
                HStack(spacing: 0) {
                    Spacer()
                    
                    FadeHorizontal(color: hoverBackground)
                    
                    HStack(spacing: 6) {
                        if let pinAction = pinAction {
                            hoverActionButton(icon: .pin) {
                                pinAction()
                            }
                        }
                        
                        if let removeAction = removeAction {
                            hoverActionButton(icon: .cross) {
                                removeAction()
                            }
                        }
                    }
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
                        delayStart: 0.4,
                        delayEnd: 0
                    )
                } else {
                    TooltipManager.shared.setTooltip(
                        nil,
                        delayEnd: 0
                    )
                }
            }
        }
        .addAnimation(dependency: isHoveredBody)
        .addBorder(
            cornerRadius: 4,
            stroke: hasHoverBorder && isHoveredBody ? .T_4 : .clear,
            dotted: true
        )
        .addButtonEffects(
            background: background,
            hoverBackground: hoverBackground,
            cornerRadius: 4,
            shouldFadeOnClick: false,
            isHovered: $isHoveredBody,
            isPressed: $isPressedBody,
            action: action
        )
    }
}

// MARK: - Child Components

extension ContextTag {
    private var textView: some View {
        Text(text)
            .styleText(
                size: 12,
                color: isHoveredRemove ? .T_3 : isHoveredBody ? hoverTextColor : textColor
            )
            .truncateText()
            .addAnimation(dependency: [isHoveredBody, isHoveredRemove])
    }
    
    private func hoverActionButton(icon: ImageResource, hoverAction: @escaping () -> Void) -> some View {
        Button {
            hoverAction()
        } label: {
            Image(icon)
                .addIconStyles(
                    foregroundColor: isHoveredRemove ? Color.primary : .gray100,
                    iconSize: 9
                )
                .addAnimation(dependency: isHoveredRemove)
        }
        .background(hoverBackground)
        .onHover { isHovering in
            isHoveredRemove = isHovering
        }
    }
}
