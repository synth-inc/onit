//
//  RemoteModelPicker.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct RemoteModelPicker: View {
    @Environment(\.model) var model

    var body: some View {
        @Bindable var model = model

        Picker("Model", selection: $model.defaultRemoteModel) {
            ForEach(model.listedModels) { aiModel in
                Text(aiModel.displayName)
                    .tag(aiModel)
            }
        }
        .labelsHidden()
    }
}
