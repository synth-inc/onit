//
//  RemoteModelPicker.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import Defaults
import SwiftUI

struct RemoteModelPicker: View {
    @Environment(\.appState) var appState
    @Default(.remoteModel) var remoteModel

    var body: some View {
        Picker(String.localized("Model", table: "Models"), selection: $remoteModel) {
            ForEach(appState.listedModels) { aiModel in
                Text(aiModel.displayName)
                    .tag(aiModel)
            }
        }
        .labelsHidden()
    }
}
