//
//  ModelToggle.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import Defaults
import SwiftUI

struct ModelToggle: View {
  @Environment(\.model) var model
  @Default(.availableRemoteModels) var availableRemoteModels
  @Default(.visibleModelIds) var visibleModelIds

  var aiModel: AIModel

  var isOn: Binding<Bool> {
    Binding {
      visibleModelIds.contains(aiModel.uniqueId)
    } set: { isOn in
      if isOn {
        visibleModelIds.insert(aiModel.uniqueId)
      } else {
        visibleModelIds.remove(aiModel.uniqueId)
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
    .onDisappear {
      if aiModel.isNew {
        // Once we've displayed the "NEW" tag in settings, the model is no longer new
        if let index = availableRemoteModels.firstIndex(where: { $0.uniqueId == aiModel.uniqueId })
        {
          availableRemoteModels[index].isNew = false
        }
      }
    }
  }
}
