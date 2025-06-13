//
//  StopGenerationButton.swift
//  Onit
//
//  Created by OpenAI on 2023-11-20.
//

import SwiftUI
import Defaults

struct StopGenerationButton: View {
    @Environment(\.windowState) private var state
    @State private var isHovered: Bool = false

    private let shortcut = KeyboardShortcut(.delete, modifiers: [.command])

    var body: some View {
        Button(action: { state.stopGeneration() }) {
            HStack(spacing: 4) {
                Image(systemName: "command")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                
                Image(systemName: "delete.left")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                
                Text("Stop")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 0)
            .frame(height: 26)
        }
        .buttonStyle(PlainButtonStyle())
        .background(isHovered ? .gray400 : .gray800)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(.gray500, lineWidth: 1)
        )
        .keyboardShortcut(shortcut)
        .onHover { hovering in
            isHovered = hovering
        }
        .addAnimation(dependency: isHovered)
    }
}
