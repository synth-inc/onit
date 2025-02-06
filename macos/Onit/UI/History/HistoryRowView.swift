//
//  HistoryRowView.swift
//  Onit
//
//  Created by Benjamin Sage on 11/4/24.
//

import SwiftUI

struct HistoryRowView: View {
  @Environment(\.model) var model

  var chat: Chat

  var body: some View {
    Button {
      model.currentChat = chat
      model.currentPrompts = chat.prompts
      model.showHistory = false
    } label: {
      HStack {
        Text(chat.prompts.first?.instruction ?? "")
          .appFont(.medium16)
          .foregroundStyle(.FG)
        Spacer()
        Text("\(chat.responseCount)")
          .appFont(.medium13)
          .monospacedDigit()
          .foregroundStyle(.gray200)
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 10)
    }
    .buttonStyle(HoverableButtonStyle(background: true))
  }
}

#if DEBUG
  #Preview {
    ModelContainerPreview {
      // TODO make samples
      //        HistoryRowView(chat: .sample)
    }
  }
#endif
