//
//  LocalModelPicker.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import Defaults
import SwiftUI

struct LocalModelPicker: View {
    @Default(.availableLocalModels) var availableLocalModels
    @Default(.visibleLocalModels) var visibleLocalModels
    @Default(.localModel) var localModel
    
    private var visibleModels: [String] {
        availableLocalModels.filter { visibleLocalModels.contains($0) }
    }

    var body: some View {
        Picker("Model", selection: $localModel) {
            ForEach(visibleModels, id: \.self) { localModel in
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
