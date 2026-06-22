//
//  PaywallCTAButton.swift
//  Onit
//
//  Created by Kévin Naudin on 12/03/25.
//

import SwiftUI

/// A standardized CTA button for paywall actions.
/// Provides consistent styling across all paywall implementations.
struct PaywallCTAButton: View {
    
    let text: String
    let action: () -> Void
    var isLoading: Bool = false
    var style: PaywallCTAStyle = .primary

    enum PaywallCTAStyle {
        case primary   // Blue background
        case secondary // Outlined
    }

    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if isLoading {
                Loader()
            }
            Text(text)
                .styleText(
                    size: 13,
                    weight: .medium,
                    color: textColor
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(7)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(borderColor, lineWidth: style == .secondary ? 1 : 0)
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .opacity(isLoading ? 0.7 : (isPressed ? 0.9 : 1))
        .contentShape(Rectangle())
        .onHover { isHovering in
            isHovered = isHovering
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isLoading {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    if !isLoading {
                        action()
                    }
                }
        )
        .allowsHitTesting(!isLoading)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }

    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return Color.blue
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            if isPressed {
                return Color.blue.opacity(0.8)
            } else if isHovered {
                return Color.blue.opacity(0.9)
            }
            return Color.blue
        case .secondary:
            if isPressed {
                return Color.gray.opacity(0.15)
            } else if isHovered {
                return Color.gray.opacity(0.1)
            }
            return Color.clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return .clear
        case .secondary:
            return Color.blue
        }
    }
}
