//
//  InputButtons.swift
//  Onit
//
//  Created by Benjamin Sage on 10/8/24.
//

import SwiftUI

struct InputButtons: View {
    @Binding var inputExpanded: Bool

    var input: Input
    var close: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ActionButton(
                icon: .smallChevRight,
                iconSize: 20,
                rotation: inputExpanded ? .degrees(90) : .zero
            ) {
                inputExpanded.toggle()
            }
            
            if let close = close {
                ActionButton(
                    icon: .cross,
                    iconSize: 9
                ) {
                    close()
                }
            }
        }
    }
}

// MARK: - Child Components

private struct ActionButton: View {
    var icon: ImageResource
    var iconSize: CGFloat
    var rotation: Angle = .zero
    var action: () -> Void
    
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false
    
    var body: some View {
        Image(icon)
            .addIconStyles(
                foregroundColor: .gray100,
                iconSize: iconSize
            )
            .frame(width: 20, height: 20)
            .rotationEffect(rotation)
            .addButtonEffects(
                hoverBackground: .gray400,
                cornerRadius: 5,
                isHovered: $isHovered,
                isPressed: $isPressed,
                action: action
            )
    }
}

#if DEBUG
    #Preview {
        InputButtons(inputExpanded: .constant(true), input: .sample)
    }
#endif
