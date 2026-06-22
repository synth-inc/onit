//
//  IconButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/8/25.
//

import SwiftUI

struct IconButton: View {
    private let pointerStyle: HoverPointerStyle
    private let icon: ImageResource?
    private let systemName: String?
    private let iconSize: CGFloat
    private let buttonSize: CGFloat
    private let isActive: Bool
    private let activeColor: Color
    private let inactiveColor: Color
    private let hoverColor: Color
    private let background: Color
    private let hoverBackground: Color
    private let activeBackground: Color
    private let cornerRadius: CGFloat
    private let activeBorderColor: Color
    private let disabled: Bool
    
    private let tooltipPrompt: String?
    private let tooltipShortcut: Tooltip.Shortcut?
    
    private let action: () -> Void
    
    init(
        pointerStyle: HoverPointerStyle = HoverPointerStyle.link,
        icon: ImageResource? = nil,
        systemName: String? = nil,
        iconSize: CGFloat = 20,
        buttonSize: CGFloat = ToolbarButtonStyle.height,
        isActive: Bool = false,
        activeColor: Color = Color.S_1,
        inactiveColor: Color = Color.T_3,
        hoverColor: Color = Color.S_0,
        background: Color = Color.clear,
        hoverBackground: Color = Color.T_8,
        activeBackground: Color = Color.T_8,
        cornerRadius: CGFloat = ToolbarButtonStyle.cornerRadius,
        activeBorderColor: Color = Color.T_6,
        disabled: Bool = false,
        
        tooltipPrompt: String? = nil,
        tooltipShortcut: Tooltip.Shortcut? = nil,
        
        action: @escaping () -> Void
    ) {
        self.pointerStyle = pointerStyle
        self.icon = icon
        self.systemName = systemName
        self.iconSize = iconSize
        self.buttonSize = buttonSize
        self.isActive = isActive
        
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.hoverColor = hoverColor
        self.background = background
        self.hoverBackground = hoverBackground
        self.activeBackground = activeBackground
        self.cornerRadius = cornerRadius
        self.activeBorderColor = activeBorderColor
        self.disabled = disabled
        
        self.tooltipPrompt = tooltipPrompt
        self.tooltipShortcut = tooltipShortcut
        
        self.action = action
    }
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    var iconColor: Color {
        if isHovered { return hoverColor }
        else if isActive { return activeColor }
        else { return inactiveColor }
    }
    
    var backgroundColor: Color {
        if isHovered { return hoverBackground }
        else if isActive { return activeBackground }
        else { return background }
    }
    
    @ViewBuilder
    private var iconImage: some View {
        if let systemName = self.systemName {
            Image(systemName: systemName)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(iconColor)
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
        } else if let icon = self.icon {
            Image(icon)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(iconColor)
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
        }
    }

    var body: some View {
        iconImage
            .frame(width: buttonSize, height: buttonSize)
            .addButtonEffects(
                pointerStyle: pointerStyle,
                background: backgroundColor,
                hoverBackground: hoverBackground,
                cornerRadius: cornerRadius,
                disabled: disabled,
                allowsHitTesting: !disabled,
                isHovered: $isHovered,
                isPressed: $isPressed,
                tooltipPrompt: tooltipPrompt,
                tooltipShortcut: tooltipShortcut
            ) {
                action()
            }
            .addBorder(
                cornerRadius: cornerRadius,
                stroke: isActive ? activeBorderColor : Color.clear
            )
            .addAnimation(dependency: isActive)
    }
}
