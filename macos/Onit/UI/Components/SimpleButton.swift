//
//  SimpleButton.swift
//  Onit
//
//  Created by Loyd Kim on 5/5/25.
//

import SwiftUI

struct SimpleButton: View {
    let iconText: String?
    let iconImage: ImageResource?
    let iconSystem: String?
    let isLoading: Bool
    let disabled: Bool
    let spacing: CGFloat
    let text: String
    let textColor: Color
    let action: () -> Void
    let background: Color
    
    init(
        iconText: String? = nil,
        iconImage: ImageResource? = nil,
        iconSystem: String? = nil,
        isLoading: Bool = false,
        disabled: Bool = false,
        spacing: CGFloat = 4,
        text: String,
        textColor: Color = Color.primary,
        action: @escaping () -> Void,
        background: Color = Color.gray400
    ) {
        self.iconText = iconText
        self.iconImage = iconImage
        self.iconSystem = iconSystem
        self.isLoading = isLoading
        self.disabled = disabled
        self.spacing = spacing
        self.text = text
        self.textColor = textColor
        self.action = action
        self.background = background
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    private var allowHitTesting: Bool {
        !isLoading && !disabled
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            if isLoading {
                Loader()
            } else if let iconText = iconText {
                Text(iconText).styleText(size: 12)
            } else if let iconSystem = iconSystem {
                Image(systemName: iconSystem)
                    .foregroundStyle(Color.primary)
            } else if let iconImage = iconImage {
                Image(iconImage)
            }
            
            Text(text).styleText(size: 13, weight: .regular, color: textColor)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(background)
        .cornerRadius(5)
        .opacity(disabled ? 0.5 : isPressed ? 0.7 : 1)
        .allowsHitTesting(allowHitTesting)
        .shadow(color: .black.opacity(0.05), radius: 0, x: 0, y: 0)
        .shadow(color: .black.opacity(0.3), radius: 1.25, x: 0, y: 0.5)
        .addAnimation(dependency: isHovered)
        .onHover { isHovering in isHovered = isHovering}
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged {_ in isPressed = true }
                .onEnded{ _ in
                    isPressed = false
                    
                    guard allowHitTesting else { return }
                    action()
                }
        )
    }
}
