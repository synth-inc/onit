//
//  ModelsTab.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct ModelsTab: View {
  @Environment(\.model) var model

  var body: some View {
    ScrollView {
      VStack(spacing: 25) {
        RemoteModelsSection()
        LocalModelsSection()
        DefaultModelsSection()
      }
      .padding(.vertical, 20)
      .padding(.horizontal, 86)
    }
  }
}

#Preview {
  ModelsTab()
}
