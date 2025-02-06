//
//  InputButtons.swift
//  Onit
//
//  Created by Benjamin Sage on 10/8/24.
//

import SwiftUI

struct InputButtons: View {
  @Environment(\.model) var model
  @Binding var inputExpanded: Bool

  var input: Input

  var body: some View {
    @Bindable var model = model

    Group {
      if input == model.pendingInput {
        Button {
          model.pendingInput = nil
        } label: {
          Image(.smallRemove)
            .renderingMode(.template)
        }
        .buttonStyle(DarkerButtonStyle())
      }

      Button {
        inputExpanded.toggle()
      } label: {
        Color.clear
          .frame(width: 20, height: 20)
          .overlay {
            Image(.smallChevRight)
              .renderingMode(.template)
              .rotationEffect(inputExpanded ? .degrees(90) : .zero)
          }
      }
    }
    .foregroundStyle(.gray200)
  }
}

#if DEBUG
  #Preview {
    ModelContainerPreview {
      InputButtons(inputExpanded: .constant(true), input: .sample)
    }
  }
#endif
