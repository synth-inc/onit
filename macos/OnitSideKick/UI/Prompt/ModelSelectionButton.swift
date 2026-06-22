//
//  ModelSelectionButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/16/25.
//

import Defaults
import SwiftUI

struct ModelSelectionButton: View {
    @Default(.remoteModel) var remoteModel
    @Default(.localModel) var localModel
    
    private var mode: InferenceMode
    
    init(mode: InferenceMode) {
        self.mode = mode
    }
    
    @State private var open: Bool = false
    
    var body: some View {
        TextButton(
            type: .clear,
            text: text,
            sizeConfig: .init(
                text: 13,
                horizontalPadding: 4,
                height: ToolbarButtonStyle.height,
                cornerRadius: 4
            )
        ) {
            Image(.smallChevDown)
                .addIconStyles(
                    foregroundColor: open ? Color.S_0 : Color.S_1,
                    iconSize: 18
                )
                .addAnimation(dependency: open)
                .rotationEffect(.degrees(open ? 180 : 0))
        } action: {
            AnalyticsManager.Chat.modelPressed(currentModel: text)
            open.toggle()
        }
        .tooltip(prompt: String.localized("Change model", table: "Sidekick"))
        .popover(isPresented: $open)  {
            ModelSelectionView(open: $open)
        }
    }
}

// MARK: - Private Variables
extension ModelSelectionButton {
    private var text: String {
        if mode == .local {
            return localModel?.split(separator: ":").first.map(String.init) ?? String.localized("Choose model", table: "Sidekick")
        } else {
            return remoteModel?.displayName ?? String.localized("Choose model", table: "Sidekick")
        }
    }
}
