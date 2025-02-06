//
//  ContextPickerItemView.swift
//  Onit
//
//  Created by Kévin Naudin on 28/01/2025.
//

import SwiftUI

struct ContextPickerItemView: View {

  let imageRes: ImageResource
  let title: String
  let subtitle: String

  var body: some View {
    HStack(spacing: 0) {
      Image(imageRes)
        .resizable()
        .frame(width: 20, height: 20)
        .padding(.leading, 12)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .appFont(.medium14)
          .foregroundColor(.white)
        Text(subtitle)
          .appFont(.medium13)
          .foregroundColor(.gray200)
      }
      .padding(.leading, 8)
      .padding(.vertical, 6)
    }
    .frame(minWidth: 210, alignment: .leading)
  }
}

#Preview {
  ContextPickerItemView(imageRes: .arrowsSpin, title: "", subtitle: "")
}
