//
//  AutoContextButton.swift
//  Onit
//
//  Created by Loyd Kim on 5/19/25.
//

import SwiftUI

struct AutoContextButton: View {
    private let icon: NSImage?
    private let text: String
    private let action: () -> Void
    private let removeAction: (() -> Void)?
    private let isAdd: Bool
    
    init(
        icon: NSImage? = nil,
        text: String,
        action: @escaping () -> Void,
        removeAction: (() -> Void)? = nil,
        isAdd: Bool = false
    ) {
        self.icon = icon
        self.text = text
        self.action = action
        self.removeAction = removeAction
        self.isAdd = isAdd
    }
    
    @State private var isHoveredBody: Bool = false
    @State private var isPressedBody: Bool = false
    @State private var isHoveredRemove: Bool = false
    
    private let height: CGFloat = 24
    
    private let textColorNotAdded = Color(hex: "#90939A") ?? .gray400
    private let textColorT2 = Color(hex: "#CDD0D9") ?? .gray100
    private let textColorT3 = Color(hex: "#AEB3BF") ?? .gray100
    
    private var hoverBackground: Color {
        return isAdd ? .gray500 : .gray400
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 6) {
                if let icon = icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .cornerRadius(4)
                }
                
                Text(text)
                    .styleText(size: 12, color: setTextColor())
                    .truncateText()
                    .addAnimation(dependency: [isHoveredBody, isHoveredRemove])
            }
            
            HStack(spacing: 0) {
                Spacer()
                
                if isAdd {
                    fade
                    plusIcon
                }
                
                if let removeAction = removeAction {
                    fade
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
        .opacity(isAdd ? isHoveredBody ? 1 : 0.5 : 1)
        .onHover { isHovering in
            isHoveredBody = isHovering
        }
        .addAnimation(dependency: isHoveredBody)
        .addButtonEffects(
            action: action,
            background: isAdd ? .clear : .gray500,
            hoverBackground: hoverBackground,
            cornerRadius: 4,
            isHovered: $isHoveredBody,
            isPressed: $isPressedBody,
            shouldFadeOnClick: false
        )
    }
}

// MARK: - Child Components

extension AutoContextButton {
    private var fade: some View {
        FadeHorizontal(color: hoverBackground)
    }
    
    private var plusIcon: some View {
        Image(.plus)
            .addIconStyles(
                foregroundColor: .white,
                iconSize: 11
            )
            .background(hoverBackground)
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

// MARK: - Private Functions

extension AutoContextButton {
    private func setTextColor() -> Color {
        if isAdd {
            if isHoveredBody {
                return textColorT2
            } else {
                return textColorNotAdded
            }
        } else {
            if isHoveredRemove {
                return textColorT3
            } else if isHoveredBody {
                return .white
            } else {
                return textColorT2
            }
        }
    }
}
