//
//  ContextButton.swift
//  Onit
//
//  Created by Loyd Kim on 5/28/25.
//

import SwiftUI

struct ContextButton: View {
    private let text: String
    private let textColor: Color
    private let hoverTextColor: Color
    private let background: Color
    private let hoverBackground: Color
    private let hasHoverBorder: Bool
    private let isLoading: Bool
    private let shouldFadeIn: Bool
    private let icon: (any View)?
    private let caption: String?
    private let tooltip: String?
    private let action: () -> Void
    private let removeAction: (() -> Void)?
    
    init(
        text: String,
        textColor: Color = .T_2,
        hoverTextColor: Color = .white,
        background: Color = .gray500,
        hoverBackground: Color = .gray400,
        hasHoverBorder: Bool = false,
        isLoading: Bool = false,
        shouldFadeIn: Bool = false,
        icon: (any View)? = nil,
        caption: String? = nil,
        tooltip: String? = nil,
        action: @escaping () -> Void,
        removeAction: (() -> Void)? = nil
    ) {
        self.text = text
        self.textColor = textColor
        self.hoverTextColor = hoverTextColor
        self.background = background
        self.hoverBackground = hoverBackground
        self.hasHoverBorder = hasHoverBorder
        self.isLoading = isLoading
        self.shouldFadeIn = shouldFadeIn
        self.icon = icon
        self.caption = caption
        self.tooltip = tooltip
        self.action = action
        self.removeAction = removeAction
    }
    
    @State private var isHoveredBody: Bool = false
    @State private var isPressedBody: Bool = false
    @State private var isHoveredRemove: Bool = false
    
    private let height: CGFloat = 24
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 6) {
                if let icon = icon { AnyView(icon) }
                
                Text(text)
                    .styleText(
                        size: 12,
                        color: isHoveredRemove ? .T_3 : isHoveredBody ? hoverTextColor : textColor
                    )
                    .truncateText()
                    .addAnimation(dependency: [isHoveredBody, isHoveredRemove])
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
        .frame(maxWidth: 155, alignment: .leading)
        .opacity(shouldFadeIn ? isHoveredBody ? 1 : 0.5 : 1)
        .onHover { isHovering in
            isHoveredBody = isHovering
        }
        .addAnimation(dependency: isHoveredBody)
        .addBorder(
            cornerRadius: 4,
            stroke: hasHoverBorder && isHoveredBody ? .T_4 : .clear,
            dotted: true
        )
        .addButtonEffects(
            action: action,
            background: background,
            hoverBackground: hoverBackground,
            cornerRadius: 4,
            isHovered: $isHoveredBody,
            isPressed: $isPressedBody,
            shouldFadeOnClick: false
        )
    }
}


// MARK: - Child Components

extension ContextButton {
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
