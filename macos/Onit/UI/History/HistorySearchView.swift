//
//  HistorySearchView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/4/24.
//

import SwiftUI

struct HistorySearchView: View {
  @Binding var text: String

  var rect: some Shape {
    .rect(cornerRadius: 10)
  }

  var body: some View {
    HStack(spacing: 8) {
      Image(.search)

      ZStack(alignment: .leading) {
        TextField("", text: $text)
          .textFieldStyle(PlainTextFieldStyle())
          .tint(.blue600.opacity(0.2))
          .fixedSize(horizontal: false, vertical: true)

        if text.isEmpty {
          placeholderView
        } else {
          Text(" ")
        }
      }
      .appFont(.medium16)
      .foregroundStyle(.white)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 10)
    .background(.gray900, in: rect)
    .overlay {
      rect.stroke(.gray700)
    }
    .padding(.horizontal, 10)
  }

  var placeholderView: some View {
    Text("Search prompts")
      .foregroundStyle(.gray300)
      .allowsHitTesting(false)
  }
}

#Preview {
  HistorySearchView(text: .constant("Hellow"))
}
