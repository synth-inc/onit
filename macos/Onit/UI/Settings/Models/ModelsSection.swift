//
//  ModelsSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct ModelsSection<Content: View>: View {
  var title: String
  @ViewBuilder var content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text(title)
        .font(.system(size: 14))
      content()
    }
    .fontWeight(.medium)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  ModelsSection(title: "Local") {
    TextField("Text here", text: .constant(""))
  }
}
