//
//  TagButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/16/25.
//

import SwiftUI

struct TagButton: View {
    private let child: (any View)?
    private let icon: ImageResource?
    private let text: String
    private let caption: String?
    private let tooltip: String?
    
    private let action: (() -> Void)?
    private let closeAction: (() -> Void)?
    
    private let maxWidth: CGFloat
    private let fill: Bool
    private let isTransparent: Bool
    
    init(
        child: (any View)? = nil,
        icon: ImageResource? = nil,
        text: String,
        caption: String? = nil,
        tooltip: String? = nil,
        
        action: (() -> Void)? = nil,
        closeAction: (() -> Void)? = nil,
        
        maxWidth: CGFloat = 0,
        fill: Bool = false,
        isTransparent: Bool = false
    ) {
        self.child = child
        self.icon = icon
        self.text = text
        self.caption = caption
        self.tooltip = tooltip
        
        self.action = action
        self.closeAction = closeAction
        
        self.maxWidth = maxWidth
        self.fill = fill
        self.isTransparent = isTransparent
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    @State private var isHoveredClose: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            if let child = child { AnyView(child) }
            
            if let icon = icon {
                Image(icon).addIconStyles(iconSize: 14)
            }
            
            Text(text)
                .styleText(size: 13)
                .truncateText()
            
            if let caption = caption {
                Text(caption)
                    .styleText(size: 13, weight: .regular, color: .gray100)
                    .truncateText()
            }
            
            if let closeAction = closeAction {
                Button { closeAction() }
                label: {
                    Image(.smallCross)
                        .addIconStyles(
                            foregroundColor: isHoveredClose ? .white : .gray100
                        )
                        .addAnimation(dependency: isHoveredClose)
                }
                .onHover{ isHovering in isHoveredClose = isHovering }
            }
        }
        .padding(.horizontal, 3)
        .frame(
            maxWidth: maxWidth > 0 ? maxWidth : fill ? .infinity : nil,
            alignment: .leading
        )
        .frame(height: 24)
        .background(setBackground())
        .scaleEffect(setScale())
        .opacity(setOpacity())
        .addBorder(
            cornerRadius: 4,
            stroke: isTransparent ? .clear : .gray400
        )
        .addAnimation(dependency: $isHovered.wrappedValue)
        .help(tooltip ?? "")
        .onHover{ isHovering in isHovered = isHovering }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged {_ in isPressed = true }
                .onEnded{ _ in
                    isPressed = false
                    if let action = action { action() }
                }
        )
    }
}

// MARK: - Private Functions
extension TagButton {
    private func setBackground() -> Color {
        if action != nil,
           isHovered
        {
            if isTransparent { return .gray800 }
            else { return .gray400 }
        } else {
            if isTransparent { return .clear }
            else { return .gray500 }
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
