//
//  ExternalTetheredButtonStyle.swift
//  Onit
//
//  Created by Kévin Naudin on 03/04/2025.
//

import SwiftUI

@MainActor
final class GradientRotationState: ObservableObject {
    static let shared = GradientRotationState()
    
    private var animationStarted = false
    @Published var rotation: Double = 0
    
    private init() {}
    
    func ensureAnimationStarted() {
        if !animationStarted {
            animationStarted = true
            rotation = rotation
        }
    }
}

struct ExternalTetheredButtonStyle: ButtonStyle {
    @Binding var dragStartTime: Date?
    @Binding var isHovering: Bool
    
    var buttonWidth = ExternalTetheredButton.width
    var buttonHeight = ExternalTetheredButton.height
    var buttonBorderWidth = ExternalTetheredButton.borderWidth
    var buttonCornerRadius: CGFloat = 12
    
    @ObservedObject private var rotationState = GradientRotationState.shared
    var tooltipText: String

    @Namespace private var animation
    
    @State var isPressed: Bool = false
    
    private var isDragging: Bool {
        dragStartTime != nil
    }
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            
            configuration.label
                .background {
                    clickBackground(configuration.isPressed)
                }
                .background {
                    RoundedCorners(radius: buttonCornerRadius, corners: .left)
                        .fill(isHovering ? .gray800 : .black.opacity(0.7))
                }
                .overlay {
                    RoundedCorners(radius: buttonCornerRadius, corners: .left)
                        .stroke(
                            isHovering ? Color.gray500 : .clear,
                            lineWidth: buttonBorderWidth
                        )
                }
        }
        .onHover { hovering in
            handleHover(hovering)
        }
        .onChange(of: configuration.isPressed) { _, pressed in
            isPressed = pressed
            
            if pressed {
                TooltipManager.shared.setTooltip(nil, delayEnd: 0)
            }
        }
        .scaleEffect(
            isDragging || isPressed ? 1.2 : isHovering ? 1.3 : 1.0,
            anchor: .trailing
        )
        .animation(
            .spring(
                response: 0.3,
                dampingFraction: 0.6
            ),
            value: isHovering
        )
    }
    
    @ViewBuilder
    private func clickBackground(_ clicked: Bool) -> some View {
        RoundedCorners(radius: buttonCornerRadius, corners: .left)
            .fill(.gray900)
            .opacity(clicked ? 1 : 0)
    }

    private func handleHover(_ hovering: Bool) {
        self.isHovering = hovering

        if hovering {
            TooltipManager.shared.setTooltip(Tooltip(prompt: tooltipText))
        } else {
            TooltipManager.shared.setTooltip(nil)
        }
    }
}
