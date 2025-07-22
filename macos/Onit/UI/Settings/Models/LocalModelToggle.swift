//
//  LocalModelToggle.swift
//  Onit
//
//  Created by Assistant on 1/13/25.
//

import Defaults
import SwiftUI

struct LocalModelToggle: View {
    @Default(.visibleLocalModels) var visibleLocalModels
    @Default(.localModel) var localModel
    @Default(.visibleLocalModels) var visibleLocalModels
    @Default(.localModel) var localModel

    let modelName: String

    var isOn: Binding<Bool> {
        Binding {
            visibleLocalModels.contains(modelName)
        } set: { isOn in
            if isOn {
                visibleLocalModels.insert(modelName)
            } else {
                visibleLocalModels.remove(modelName)
                
                // Handle edge case: if the currently selected local model is being deselected
                if modelName == localModel {
                    // Try to find another visible local model to select
                    if let firstVisibleModel = visibleLocalModels.first {
                        localModel = firstVisibleModel
                    } else {
                        // No visible local models left, clear the selection
                        localModel = nil
                    }
                }
            }
        }
    }

    var body: some View {
        Toggle(isOn: isOn) {
            Text(modelName)
                .font(.system(size: 13))
                .fontWeight(.regular)
                .opacity(0.85)
        }
    }
} 