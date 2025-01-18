//
//  LocalModelPicker.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import SwiftUI

struct LocalModelPicker: View {
    @Environment(\.model) var model

    var body: some View {
        @Bindable var model = model

        Picker("Model", selection: $model.defaultLocalModel) {
            ForEach(model.preferences.availableLocalModels, id: \.self) { localModel in
                Text(localModel)
                    .tag(localModel)
            }
        }
        .labelsHidden()
    }
}

#Preview {
    LocalModelPicker()
}
