//
//  LocalModelPicker.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import Defaults
import SwiftUI

struct LocalModelPicker: View {
    @Environment(\.model) var model
    @Default(.availableLocalModels) var availableLocalModels
    @Default(.localModel) var localModel

    var body: some View {
        @Bindable var model = model

        Picker("Model", selection: $localModel) {
            ForEach(availableLocalModels, id: \.self) { localModel in
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
