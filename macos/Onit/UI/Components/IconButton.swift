//
//  IconButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/8/25.
//

import SwiftUI

struct IconButton: View {
    private let icon: ImageResource
    private let iconSize: CGFloat
    private let buttonSize: CGFloat
    private let isActive: Bool
    private let activeColor: Color
    private let inactiveColor: Color
    private let hoverBackground: Color
    private let activeBackground: Color
    private let cornerRadius: CGFloat
    private let activeBorderColor: Color
    
    private let tooltipPrompt: String?
    private let tooltipShortcut: Tooltip.Shortcut?
    
    private let action: () -> Void
    
    init(
        icon: ImageResource,
        iconSize: CGFloat = 20,
        buttonSize: CGFloat = ToolbarButtonStyle.height,
        isActive: Bool = false,
        activeColor: Color = .gray100,
        inactiveColor: Color = .gray200,
        hoverBackground: Color = .gray800,
        activeBackground: Color = .gray800,
        cornerRadius: CGFloat = ToolbarButtonStyle.cornerRadius,
        activeBorderColor: Color = .gray500,
        
        tooltipPrompt: String? = nil,
        tooltipShortcut: Tooltip.Shortcut? = nil,
        
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconSize = iconSize
        self.buttonSize = buttonSize
        self.isActive = isActive
        
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.hoverBackground = hoverBackground
        self.activeBackground = activeBackground
        self.cornerRadius = cornerRadius
        self.activeBorderColor = activeBorderColor
        
        self.tooltipPrompt = tooltipPrompt
        self.tooltipShortcut = tooltipShortcut
        
        self.action = action
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    var iconColor: Color {
        if isHovered { return .white }
        else if isActive { return activeColor }
        else { return inactiveColor }
    }
    
    var background: Color {
        if isHovered { return hoverBackground }
        else if isActive { return activeBackground }
        else { return .clear }
    }
    
    var body: some View {
        Image(icon)
            .resizable()
            .renderingMode(.template)
            .foregroundColor(iconColor)
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
            .frame(width: buttonSize, height: buttonSize)
            .addButtonEffects(
                background: background,
                hoverBackground: hoverBackground,
                cornerRadius: cornerRadius,
                isHovered: $isHovered,
                isPressed: $isPressed
            ) {
                action()
            }
            .addBorder(
                cornerRadius: cornerRadius,
                stroke: isActive ? activeBorderColor : .clear
            )
            .addAnimation(dependency: isActive)
            .onChange(of: isHovered) { _, isHovering in
                TooltipHelpers.setTooltipOnHover(
                    isHovering: isHovering,
                    tooltipPrompt: tooltipPrompt,
                    tooltipShortcut: tooltipShortcut ?? .none
                )
            }
    }
}
