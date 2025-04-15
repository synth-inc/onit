//
//  ActionButton.swift
//  Onit
//
//  Created by - on 4/14/25.
//

import SwiftUI

struct ActionButton<Child: View>: View {
    private let icon: ImageResource?
    private let iconSize: CGFloat
    private let action: () -> Void
    private let text: String
    @ViewBuilder private let child: () -> Child
    
    init(
        icon: ImageResource? = nil,
        iconSize: CGFloat = 20,
        action: @escaping () -> Void,
        text: String,
        @ViewBuilder child: @escaping () -> Child
    ) {
        self.icon = icon
        self.iconSize = iconSize
        self.action = action
        self.text = text
        self.child = child
    }
    
    @State private var hovered: Bool = false
    @State private var isPressed: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if let icon = icon { Image(icon).addIconStyles(iconSize: iconSize) }
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .truncateText()
            
            Spacer()
            
            child()
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .background(hovered ? .gray600 : .clear)
        .opacity(isPressed ? 0.7 : 1)
        .cornerRadius(8)
        .addAnimation(value: $hovered)
        .onHover{ isHovering in hovered = isHovering }
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

// Allows `child` prop to be optional.
extension ActionButton where Child == EmptyView {
    init(
        icon: ImageResource? = nil,
        iconSize: CGFloat = 20,
        action: @escaping () -> Void,
        text: String
    ) {
        self.init(
            icon: icon,
            iconSize: iconSize,
            action: action,
            text: text
        ) {
            EmptyView()
        }
    }
}
