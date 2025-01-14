//
//  LocalModelPicker.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import SwiftUI

struct LocalModelPicker: View {
    @Environment(\.model) var model

    @State private var aiModel = ""

    var body: some View {
        Picker("Model", selection: $aiModel) {
            ForEach(model.availableLocalModels, id: \.self) { aiModel in
                Text(aiModel)
                    .tag(aiModel)
            }
        }
        .labelsHidden()
    }
}

#Preview {
    LocalModelPicker()
}
