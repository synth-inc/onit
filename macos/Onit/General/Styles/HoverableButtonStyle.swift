//
//  HoverableButton.swift
//  Onit
//
//  Created by Benjamin Sage on 9/20/24.
//

import SwiftUI

struct HoverableButtonStyle: ButtonStyle {
    @State private var hovering = false
    @State private var frame: CGRect = .zero

    var tooltip: Tooltip?
    var background: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                clickBackground(configuration.isPressed)
            }
            .background {
                hoverBackground
            }
            .onHover { hovering in
                handleHover(hovering)
            }
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            frame = proxy.frame(in: .global)
                        }
                        .onChange(of: proxy.frame(in: .global)) { _, value in
                            frame = value
                        }
                }
            }
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    TooltipManager.shared.setTooltip(nil, immediate: true)
                }
            }
    }

    @ViewBuilder
    private func clickBackground(_ clicked: Bool) -> some View {
        if background {
            RoundedRectangle(cornerRadius: 6)
                .fill(.gray600)
                .opacity(clicked ? 1 : 0)
        }
    }

    @ViewBuilder
    private var hoverBackground: some View {
        if background {
            RoundedRectangle(cornerRadius: 6)
                .fill(.gray800)
                .opacity(hovering ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: hovering)
        }
    }

    private func handleHover(_ hovering: Bool) {
        self.hovering = hovering

        if hovering {
            TooltipManager.shared.setTooltip(tooltip)
        } else {
            TooltipManager.shared.setTooltip(nil)
        }
    }
}

#if DEBUG
    #Preview {
        Color.black
            .overlay {
                Button {

                } label: {
                    Text(.sample)
                        .padding()
                }
                .buttonStyle(
                    HoverableButtonStyle(tooltip: .sample, background: true)
                )
            }
    }
#endif
