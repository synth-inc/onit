//
//  ModelToggle.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct ModelToggle: View {
    @Environment(\.model) var model

    var aiModel: AIModel

    var isOn: Binding<Bool> {
        Binding {
            model.preferences.visibleModels.contains(aiModel)
        } set: { isOn in
            if isOn {
                model.preferences.visibleModels.insert(aiModel)
            } else {
                model.preferences.visibleModels.remove(aiModel)
            }
        }
    }

    var body: some View {
        Toggle(aiModel.displayName, isOn: isOn)
    }
}
