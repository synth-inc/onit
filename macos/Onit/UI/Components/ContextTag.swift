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
    private let hasHoverBorder: Bool
    private let maxWidth: CGFloat
    private let isLoading: Bool
    private let shouldFadeIn: Bool
    private let iconBundleURL: URL?
    private let iconView: (any View)?
    private let caption: String?
    private let tooltip: String?
    private let action: (() -> Void)?
    private let removeAction: (() -> Void)?
    
    init(
        text: String,
        textColor: Color = .T_2,
        hoverTextColor: Color = .white,
        background: Color = .gray500,
        hoverBackground: Color = .gray400,
        borderColor: Color = .clear,
        hasHoverBorder: Bool = false,
        maxWidth: CGFloat = 155,
        isLoading: Bool = false,
        shouldFadeIn: Bool = false,
        iconBundleURL: URL? = nil,
        iconView: (any View)? = nil,
        caption: String? = nil,
        tooltip: String? = nil,
        action: (() -> Void)? = nil,
        removeAction: (() -> Void)? = nil
    ) {
        self.text = text
        self.textColor = textColor
        self.hoverTextColor = hoverTextColor
        self.background = background
        self.hoverBackground = hoverBackground
        self.borderColor = borderColor
        self.hasHoverBorder = hasHoverBorder
        self.maxWidth = maxWidth
        self.isLoading = isLoading
        self.shouldFadeIn = shouldFadeIn
        self.iconBundleURL = iconBundleURL
        self.iconView = iconView
        self.caption = caption
        self.tooltip = tooltip
        self.action = action
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
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 6) {
                if let bundleUrlIcon = bundleUrlIcon {
                    Image(nsImage: bundleUrlIcon)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .cornerRadius(4)
                }
                
                if let iconView = iconView {
                    AnyView(iconView)
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
            
            HStack(spacing: 0) {
                Spacer()
                
                if let removeAction = removeAction {
                    FadeHorizontal(color: hoverBackground)
                    removeButton(removeAction)
                }
            }
            .frame(height: height)
            .opacity(isHoveredBody ? 1 : 0)
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
            stroke: borderColor != .clear ? borderColor : (hasHoverBorder && isHoveredBody ? .T_4 : .clear),
            dotted: borderColor == .clear && hasHoverBorder && isHoveredBody
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
    
    private func removeButton(_ removeAction: @escaping () -> Void) -> some View {
        Button {
            removeAction()
        } label: {
            Image(.cross)
                .addIconStyles(
                    foregroundColor: isHoveredRemove ? .white : .gray100,
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
