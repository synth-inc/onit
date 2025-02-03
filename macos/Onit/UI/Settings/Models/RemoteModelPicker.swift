//
//  RemoteModelPicker.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI
import Defaults

struct RemoteModelPicker: View {
    @Environment(\.remoteModels) var remoteModels
    @Default(.remoteModel) var remoteModel

    var body: some View {
        Picker("Model", selection: $remoteModel) {
            ForEach(remoteModels.listedModels) { aiModel in
                Text(aiModel.displayName)
                    .tag(aiModel)
            }
        }
        .labelsHidden()
    }
}
