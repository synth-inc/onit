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
                Preferences.save(model.preferences)
            } else {
                model.preferences.visibleModelIds.remove(aiModel.id)
                Preferences.save(model.preferences)
            }
        }
    }

    var body: some View {
        Toggle(isOn: isOn) {
            HStack {
                Text(aiModel.displayName)
                    .font(.system(size: 13))
                    .fontWeight(.regular)
                    .opacity(0.85)
                if aiModel.isNew {
                    Text("NEW")
                        .font(.system(size: 11))
                        .fontWeight(.bold)
                        .foregroundColor(.blue400)
                }
                if aiModel.isDeprecated {
                    HStack(spacing: 4) {
                        Image(.warningSettings)
                        Text("Model deprecated")
                            .font(.system(size: 11))
                    }
                }
            }
        }
        .onDisappear() {
            if aiModel.isNew {
                // Once we've displayed the "NEW" tag in settings, the model is no longer new
                model.preferences.markRemoteModelAsNotNew(modelId: aiModel.id)
                Preferences.save(model.preferences)
            }
        }
    }
}
