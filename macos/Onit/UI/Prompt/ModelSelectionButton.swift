//
//  ModelSelectionButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/16/25.
//

import Defaults
import SwiftUI

struct ModelSelectionButton: View {
    @Environment(\.model) var model
    
    @Default(.mode) var mode
    @Default(.remoteModel) var remoteModel
    @Default(.localModel) var localModel
    
    var showModelBinding: Binding<Bool> {
        Binding(
            get: { self.model.showModels },
            set: { self.model.showModels = $0 }
        )
    }
    
    var body: some View {
        ActionButton(
            text: text,
            action: { model.showModels.toggle() },
            width: 90,
            height: toolbarButtonHeight,
            fillContainer: false,
            horizontalPadding: 4,
            cornerRadius: 4,
            fontSize: 12,
            fontWeight: .semibold,
            fontColor: .gray200
        ) {
            Image(.smallChevDown)
                .addIconStyles(
                    foregroundColor: model.showModels ? .white : .gray100
                )
                .addAnimation(dependency: model.showModels)
                .rotationEffect(.degrees(model.showModels ? 180 : 0))
        }
        .tooltip(prompt: "Change model")
        .popover(
            isPresented: showModelBinding,
            arrowEdge: .bottom
        )  {
            ModelSelectionView()
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
