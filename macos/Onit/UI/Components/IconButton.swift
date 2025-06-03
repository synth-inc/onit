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
    private let action: () -> Void
    private let isActive: Bool
    private let activeColor: Color?
    private let inactiveColor: Color?
    private let tooltipPrompt: String?
    private let tooltipShortcut: Tooltip.Shortcut?
    
    init(
        icon: ImageResource,
        iconSize: CGFloat = 20,
        buttonSize: CGFloat = ToolbarButtonStyle.height,
        action: @escaping () -> Void,
        isActive: Bool = false,
        activeColor: Color? = nil,
        inactiveColor: Color? = nil,
        tooltipPrompt: String? = nil,
        tooltipShortcut: Tooltip.Shortcut? = nil
    ) {
        self.icon = icon
        self.iconSize = iconSize
        self.buttonSize = buttonSize
        self.action = action
        self.isActive = isActive
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.tooltipPrompt = tooltipPrompt
        self.tooltipShortcut = tooltipShortcut
    }
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        if let prompt = tooltipPrompt,
           let shortcut = tooltipShortcut {
            tooltipShortcutButton(prompt: prompt, shortcut: shortcut)
        } else if let prompt = tooltipPrompt {
            tooltipButton(prompt: prompt)
        } else {
            plainButton
        }
    }
}

// MARK: - Child Components

extension IconButton {
    private var iconImage: some View {
        Image(icon)
            .resizable()
            .renderingMode(.template)
            .foregroundColor(handleIconColor())
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
    }
    
    private func tooltipShortcutButton(prompt: String, shortcut: Tooltip.Shortcut) -> some View {
        Button { action() }
        label: { iconImage }
            .tooltip(prompt: prompt, shortcut: shortcut)
            .applySharedStyles(
                buttonSize: buttonSize,
                isHovered: $isHovered,
                isActive: isActive
            )
    }
    
    private func tooltipButton(prompt: String) -> some View {
        Button { action() }
        label: { iconImage }
            .tooltip(prompt: prompt)
            .applySharedStyles(
                buttonSize: buttonSize,
                isHovered: $isHovered,
                isActive: isActive
            )
    }
    
    private var plainButton: some View {
        Button { action() }
        label: { iconImage }
            .applySharedStyles(
                buttonSize: buttonSize,
                isHovered: $isHovered,
                isActive: isActive
            )
    }
}

// MARK: - Private Functions

extension IconButton {
    private func handleIconColor() -> Color {
        if isActive {
            return activeColor ?? .gray100
        } else if isHovered {
            return .white
        } else {
            return inactiveColor ?? .gray200
        }
    }
}

// MARK: - Extending View

private extension View {
    func applySharedStyles(
        buttonSize: CGFloat,
        isHovered: Binding<Bool>,
        isActive: Bool
    ) -> some View {
        
        return self
            .buttonStyle(PlainButtonStyle())
            .frame(width: buttonSize, height: buttonSize)
            .background((isHovered.wrappedValue || isActive) ? .gray800 : .clear)
            .addBorder(
                cornerRadius: ToolbarButtonStyle.cornerRadius,
                stroke: isActive ? .gray500 : .clear
            )
            .addAnimation(dependency: isHovered.wrappedValue)
            .onHover{ isHovering in isHovered.wrappedValue = isHovering }
    }
}
