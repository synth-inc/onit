//
//  DefaultModelsSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct DefaultModelsSection: View {
  var body: some View {
    ModelsSection(title: "Default models") {
      Form {
        remote
        local
      }
      .formStyle(.grouped)
      .font(.system(size: 13))
      .fontWeight(.regular)
      .padding(-20)
    }
  }

  var remote: some View {
    HStack {
      Text("Remote")
      Spacer()
      RemoteModelPicker()
    }
  }

  var local: some View {
    HStack {
      Text("Local")
      Spacer()
      LocalModelPicker()
    }
  }
}

#Preview {
  DefaultModelsSection()
}
