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
            model.preferences.visibleModelIds.contains(aiModel.id)
        } set: { isOn in
            if isOn {
                model.preferences.visibleModelIds.insert(aiModel.id)
            } else {
                model.preferences.visibleModelIds.remove(aiModel.id)
            }
        }
    }

    var body: some View {
        Toggle(isOn: isOn) {
            Text(aiModel.displayName)
                .font(.system(size: 13))
                .fontWeight(.regular)
                .opacity(0.85)
        }
    }
}
