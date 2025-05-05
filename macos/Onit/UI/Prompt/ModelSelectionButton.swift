//
//  ModelSelectionButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/16/25.
//

import Defaults
import SwiftUI

struct ModelSelectionButton: View {
    @Environment(\.windowState) private var state
    @Environment(\.appState) private var appState
    
    @Default(.mode) var mode
    @Default(.remoteModel) var remoteModel
    @Default(.localModel) var localModel
    
    @State private var open: Bool = false
    
    var body: some View {
        TextButton(
            text: text,
            action: { open.toggle() },
            gap: 0,
            height: ToolbarButtonStyle.height,
            fillContainer: false,
            horizontalPadding: 4,
            cornerRadius: 4,
            fontSize: 13,
            fontColor: .gray200
        ) {
            Image(.smallChevDown)
                .addIconStyles(
                    foregroundColor: open ? .white : .gray100,
                    iconSize: 18
                )
                .addAnimation(dependency: open)
                .rotationEffect(.degrees(open ? 180 : 0))
        }
        .tooltip(prompt: "Change model")
        .popover(isPresented: $open)  {
            ModelSelectionView(open: $open)
        }
    }
}

// MARK: - Private Variables
extension ModelSelectionButton {
    private var text: String {
        if mode == .local {
            return localModel?.split(separator: ":").first.map(String.init) ?? "Choose model"
        } else {
            return remoteModel?.displayName ?? "Choose model"
        }
    }
}
