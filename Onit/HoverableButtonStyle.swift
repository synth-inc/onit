//
//  HoverableButton.swift
//  Omni
//
//  Created by Benjamin Sage on 9/20/24.
//

import SwiftUI
import BenKit

struct HoverableButtonStyle: ButtonStyle {
    @State private var hovering = false
    @State private var showTooltip = false
    @State private var tooltipTask: Task<Void, Never>?

    var prompt: String?
    var shortcut: KeyboardShortcut?
    var tooltip: Tooltip?

    @State private var tooltipHeight: CGFloat = 0

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                hoverBackground
            }
            .onHover { hovering in
                handleHover(hovering)
            }
            .overlay(alignment: .bottom) {
                tooltipView
            }
    }

    private var hoverBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(.gray800)
            .opacity(hovering ? 1 : 0)
    }

    @ViewBuilder
    private var tooltipView: some View {
        if showTooltip, let tooltip {
            HStack {
                Text(tooltip.prompt)
                    .appFont(.medium12)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        tooltipBackground
                    }
            }
            .padding(2)
            .measure(.height, updating: false, $tooltipHeight)
            .offset(y: tooltipHeight)
        }
    }

    var tooltipBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray500)
            .shadow(color: .black.opacity(0.36), radius: 2.5, x: 0, y: 0)
    }

    private func handleHover(_ hovering: Bool) {
        self.hovering = hovering

        if hovering {
            tooltipTask = Task {
                await sleep(0.5)
                if Task.isCancelled { return }
                showTooltip = true
            }
        } else {
            tooltipTask?.cancel()
            withAnimation {
                showTooltip = false
            }
        }
    }
}

#Preview {
    Color.black
        .overlay {
            Button {

            } label: {
                Text(.sample)
                    .padding()
            }
            .buttonStyle(HoverableButtonStyle(tooltip: .sample))
        }
}
