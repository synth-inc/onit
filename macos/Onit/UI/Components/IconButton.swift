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
    private let action: () -> Void
    private let isActive: Bool
    private let activeColor: Color?
    private let inactiveColor: Color?
    private let tooltipPrompt: String?
    private let tooltipShortcut: Tooltip.Shortcut?
    
    init(
        icon: ImageResource,
        iconSize: CGFloat = 20,
        action: @escaping () -> Void,
        isActive: Bool = false,
        activeColor: Color? = nil,
        inactiveColor: Color? = nil,
        tooltipPrompt: String? = nil,
        tooltipShortcut: Tooltip.Shortcut? = nil
    ) {
        self.icon = icon
        self.iconSize = iconSize
        self.action = action
        self.isActive = isActive
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.tooltipPrompt = tooltipPrompt
        self.tooltipShortcut = tooltipShortcut
    }
    
    @State private var hovered: Bool = false
    
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

/// Child Components
extension IconButton {
    private var iconImage: some View {
        Image(icon)
            .resizable()
            .renderingMode(.template)
            .foregroundColor(handleIconColor())
            .frame(width: iconSize, height: iconSize)
    }
    
    private func tooltipShortcutButton(prompt: String, shortcut: Tooltip.Shortcut) -> some View {
        Button { action() }
        label: { iconImage }
            .tooltip(prompt: prompt, shortcut: shortcut)
            .applySharedStyles(hovered: $hovered, isActive: isActive)
    }
    
    private func tooltipButton(prompt: String) -> some View {
        Button { action() }
        label: { iconImage }
            .tooltip(prompt: prompt)
            .applySharedStyles(hovered: $hovered, isActive: isActive)
    }
    
    private var plainButton: some View {
        Button { action() }
        label: { iconImage }
            .applySharedStyles(hovered: $hovered, isActive: isActive)
    }
}

/// Private Functions
extension IconButton {
    private func handleIconColor() -> Color {
        if isActive {
            return activeColor ?? .white
        } else if hovered {
            return .gray100
        } else {
            return inactiveColor ?? .gray200
        }
    }
}

extension View {
    func applySharedStyles(
        hovered: Binding<Bool>,
        isActive: Bool
    ) -> some View {
        self
            .buttonStyle(PlainButtonStyle())
            .frame(width: defaultButtonHeight, height: defaultButtonHeight)
            .background((hovered.wrappedValue || isActive) ? .gray800 : .clear)
            .addBorderRadius(
                cornerRadius: defaultButtonCornerRadius,
                stroke: isActive ? .gray500 : .clear
            )
            .addAnimation(value: hovered)
            .cornerRadius(4)
            .onHover{ isHovering in hovered.wrappedValue = isHovering }
    }
}
