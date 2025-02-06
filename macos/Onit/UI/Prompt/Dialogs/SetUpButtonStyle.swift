//
//  SetUpButton.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct SetUpButtonStyle: ButtonStyle {
  var showArrow: Bool

  @State private var hovering = false

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 3) {
      configuration.label
      if showArrow {
        Text("→")
          .offset(x: hovering ? 2 : 0)
      }
    }

    .padding(8)
    .foregroundStyle(.FG)
    .background(.blue400.opacity(hovering ? 0.9 : 1), in: .rect(cornerRadius: 8))
    .opacity(configuration.isPressed ? 0.9 : 1)
    .animation(.spring(duration: 1 / 3), value: hovering)
    .fontWeight(.semibold)
    .onContinuousHover { phase in
      if case .active = phase {
        hovering = true
      } else {
        hovering = false
      }
    }
  }
}
