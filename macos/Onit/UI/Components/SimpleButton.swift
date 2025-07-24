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
    let isLoading: Bool
    let text: String
    let textColor: Color
    let action: () -> Void
    let background: Color
    
    init(
        iconText: String? = nil,
        iconImage: ImageResource? = nil,
        isLoading: Bool = false,
        text: String,
        textColor: Color = Color.white,
        action: @escaping () -> Void,
        background: Color = Color.gray400
    ) {
        self.iconText = iconText
        self.iconImage = iconImage
        self.isLoading = isLoading
        self.text = text
        self.textColor = textColor
        self.action = action
        self.background = background
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            if let iconText = iconText {
                Text(iconText).styleText(size: 12)
            } else if let iconImage = iconImage {
                Image(iconImage)
            }
            
            if isLoading {
                Loader()
            }
            
            Text(text).styleText(size: 13, weight: .regular, color: textColor)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(background)
        .cornerRadius(5)
        .opacity(isPressed ? 0.7 : 1)
        .shadow(color: .black.opacity(0.05), radius: 0, x: 0, y: 0)
        .shadow(color: .black.opacity(0.3), radius: 1.25, x: 0, y: 0.5)
        .addAnimation(dependency: isHovered)
        .onHover { isHovering in isHovered = isHovering}
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged {_ in isPressed = true }
                .onEnded{ _ in
                    isPressed = false
                    action()
                }
        )
    }
}
