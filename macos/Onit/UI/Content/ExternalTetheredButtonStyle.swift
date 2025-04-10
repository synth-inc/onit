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
    @Binding var hovering: Bool
    @Binding var containsInput: Bool

    @ObservedObject private var rotationState = GradientRotationState.shared
    var tooltipText: String

    @Namespace private var animation
    
    func makeBody(configuration: Configuration) -> some View {
        
        ZStack {
            if containsInput {
                backgroundForInput
                    .matchedGeometryEffect(id: "background", in: animation)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
            
            configuration.label
                .background {
                    clickBackground(configuration.isPressed)
                }
                .background {
                    RoundedLeftCorners(radius: ExternalTetheredButton.width * 0.66)
                        .fill(hovering ? .gray800 : .black)
                        .padding([.leading, .top, .bottom], containsInput ? ExternalTetheredButton.borderWidth : 0)
                }
                .overlay {
                    RoundedLeftCorners(radius: (ExternalTetheredButton.width + 2) * 0.66)
                        .stroke(Color.gray500, lineWidth: 1)
                }
        }
        .onHover { hovering in
            handleHover(hovering)
        }
        .onChange(of: configuration.isPressed) { _, pressed in
            if pressed {
                TooltipManager.shared.setTooltip(nil, immediate: true)
            }
        }
        .scaleEffect(hovering ? 1.3 : 1.0, anchor: .trailing)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hovering)
    }

    private var backgroundForInput: some View {
        HStack {
            Rectangle()
                .fill(
                    AngularGradient(gradient: Gradient(colors: [
                        Color(red: 0.78, green: 0.76, blue: 0.93),
                        Color(red: 0.5, green: 0.45, blue: 0.83),
                        Color(red: 0.43, green: 0.42, blue: 0.99)
                    ]), center: .center)
                )
                .frame(width: ExternalTetheredButton.height, height: ExternalTetheredButton.height)
                .rotationEffect(.degrees(rotationState.rotation))
        }
        .mask {
            RoundedLeftCorners(radius: (ExternalTetheredButton.width + (ExternalTetheredButton.borderWidth * 2))  * 0.66)
                .frame(width: ExternalTetheredButton.width + (ExternalTetheredButton.borderWidth * 2),
                       height: ExternalTetheredButton.height + (ExternalTetheredButton.borderWidth * 2))
        }
        .blur(radius: 2)
        .frame(width: ExternalTetheredButton.width + (ExternalTetheredButton.borderWidth * 2))
        .onAppear {
            rotationState.ensureAnimationStarted()
            
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                rotationState.rotation += 360
            }
        }
    }
    
    @ViewBuilder
    private func clickBackground(_ clicked: Bool) -> some View {
        RoundedLeftCorners(radius: ExternalTetheredButton.width / 2)
            .fill(.gray900)
            .opacity(clicked ? 1 : 0)
    }

    private func handleHover(_ hovering: Bool) {
        self.hovering = hovering

        if hovering {
            TooltipManager.shared.setTooltip(Tooltip(prompt: tooltipText))
        } else {
            TooltipManager.shared.setTooltip(nil)
        }
    }
}
