//
//  HistoryTitle.swift
//  Onit
//
//  Created by Benjamin Sage on 11/4/24.
//

import SwiftUI

struct HistoryTitle: View {
  @Environment(\.model) var model

  var body: some View {
    HStack {
      Text("History")
        .appFont(.medium14)
        .foregroundStyle(.FG)
      Spacer()
      Button {
        model.showHistory = false
      } label: {
        Color.clear
          .frame(width: 20, height: 20)
          .overlay {
            Image(.smallCross)
              .renderingMode(.template)
              .foregroundStyle(.gray200)
          }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }
}

#if DEBUG
  #Preview {
    ModelContainerPreview {
      HistoryTitle()
    }
  }
#endif
