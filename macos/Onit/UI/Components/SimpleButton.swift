//
//  SimpleButton.swift
//  Onit
//
//  Created by Loyd Kim on 5/5/25.
//

import SwiftUI

struct SimpleButton: View {
    let text: String
    let loading: Bool
    let disabled: Bool
    let spacing: CGFloat
    let textColor: Color
    let background: Color
    let iconText: String?
    let iconSystem: String?
    let iconImage: ImageResource?
    let action: (() -> Void)?
    
    init(
        text: String,
        loading: Bool = false,
        disabled: Bool = false,
        spacing: CGFloat = 4,
        textColor: Color = Color.primary,
        background: Color = Color.gray400,
        iconText: String? = nil,
        iconSystem: String? = nil,
        iconImage: ImageResource? = nil,
        action: (() -> Void)? = nil
    ) {
        self.text = text
        self.loading = loading
        self.disabled = disabled
        self.spacing = spacing
        self.textColor = textColor
        self.background = background
        self.iconText = iconText
        self.iconSystem = iconSystem
        self.iconImage = iconImage
        self.action = action
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            if loading {
                Loader(size: 20)
            } else if let iconText = iconText {
                Text(iconText).styleText(size: 12)
            } else if let iconSystem = iconSystem {
                Image(systemName: iconSystem)
                    .foregroundStyle(Color.primary)
            } else if let iconImage = iconImage {
                Image(iconImage)
            }
            
            Text(text)
                .styleText(
                    size: 13,
                    weight: .light,
                    color: textColor
                )
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(background)
        .cornerRadius(5)
        .opacity(disabled ? 0.5 : isPressed && action != nil ? 0.7 : 1)
        .allowsHitTesting(!disabled)
        .shadow(color: .black.opacity(0.05), radius: 0, x: 0, y: 0)
        .shadow(color: .black.opacity(0.3), radius: 1.25, x: 0, y: 0.5)
        .addAnimation(dependency: isHovered)
        .onHover { isHovering in isHovered = isHovering}
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged {_ in isPressed = true }
                .onEnded{ _ in
                    isPressed = false
                    action?()
                }
        )
    }
}
