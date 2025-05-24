//
//  TagButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/16/25.
//

import SwiftUI

struct TagButton: View {
    private let text: String
    private let maxWidth: CGFloat
    private let fill: Bool
    private let isTransparent: Bool
    private let borderColor: Color
    
    private let child: (any View)?
    private let icon: ImageResource?
    private let caption: String?
    private let tooltip: String?
    
    private let action: (() -> Void)?
    private let closeAction: (() -> Void)?
    
    init(
        text: String,
        maxWidth: CGFloat = 0,
        fill: Bool = false,
        isTransparent: Bool = false,
        borderColor: Color = .gray400,
        
        child: (any View)? = nil,
        icon: ImageResource? = nil,
        caption: String? = nil,
        tooltip: String? = nil,
        
        action: (() -> Void)? = nil,
        closeAction: (() -> Void)? = nil
    ) {
        self.text = text
        self.maxWidth = maxWidth
        self.fill = fill
        self.isTransparent = isTransparent
        self.borderColor = borderColor
        
        self.child = child
        self.icon = icon
        self.caption = caption
        self.tooltip = tooltip
        
        self.action = action
        self.closeAction = closeAction
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    @State private var isHoveredClose: Bool = false
    
    private var addIconPadding: Bool {
        child != nil || icon != nil
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 6) {
                if let child = child { AnyView(child) }
                
                if let icon = icon {
                    Image(icon).addIconStyles(iconSize: 14)
                }
                
                Text(text)
                    .styleText(
                        size: 12,
                        color: isHoveredClose ? .T_3 : .white
                    )
                    .truncateText()
                
                if let caption = caption {
                    Text(caption)
                        .styleText(size: 13, weight: .regular, color: .gray100)
                        .truncateText()
                }
            }
            
            if let closeAction = closeAction {
                HStack(spacing: 0) {
                    Spacer()
                    FadeHorizontal(color: setHoverBackground())
                    closeButton(closeAction)
                }
                .opacity(isHovered ? 1 : 0)
            }
        }
        .padding(.leading, addIconPadding ? 4 : 3)
        .padding(.trailing, 6)
        .frame(
            maxWidth: maxWidth > 0 ? maxWidth : fill ? .infinity : nil,
            alignment: .leading
        )
        .frame(height: 24)
        .addBorder(
            cornerRadius: 4,
            stroke: isTransparent ? .clear : borderColor
        )
        .help(tooltip ?? "")
        .addAnimation(dependency: isHoveredClose)
        .addButtonEffects(
            action: action,
            background: isTransparent ? .clear : .gray500,
            hoverBackground: setHoverBackground(),
            cornerRadius: 4,
            isHovered: $isHovered,
            isPressed: $isPressed
        )
        .allowsHitTesting(action != nil)
    }
}

// MARK: - Child Components

extension TagButton {
    private func closeButton(_ closeAction: @escaping () -> Void) -> some View {
        Button {
            closeAction()
        } label: {
            Image(.cross)
                .addIconStyles(
                    foregroundColor: isHoveredClose ? .white : .gray100,
                    iconSize: 9
                )
                .addAnimation(dependency: isHoveredClose)
        }
        .background(setHoverBackground())
        .onHover{ isHovering in
            isHoveredClose = isHovering
        }
    }
}

// MARK: - Private Functions
extension TagButton {
    private func setHoverBackground() -> Color {
        if action == nil {
            if isTransparent { return .clear }
            else { return .gray500 }
        } else {
            if isTransparent { return .gray800 }
            else { return .gray400 }
        }
    }
    
    private func setScale() -> CGFloat {
        if let _ = action { return isPressed ? 0.99 : 1 }
        else { return 1 }
    }
    
    private func setOpacity() -> Double {
        if let _ = action { return isPressed ? 0.7 : 1 }
        else { return 1 }
    }
}
