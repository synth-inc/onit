//
//  OnitPromptView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import KeyboardShortcuts
import SwiftUI

struct OnitPromptView: View {
  @Environment(\.model) var model

  var shortcut: KeyboardShortcut? {
    KeyboardShortcuts.getShortcut(for: .launch)?.native
  }

  var body: some View {
    if model.panel == nil {
      HStack(spacing: 3) {
        Image(.smirk)
          .resizable()
          .renderingMode(.template)
          .scaledToFit()
          .frame(width: 14, height: 14)
        KeyboardShortcutView(shortcut: shortcut, characterWidth: 12, spacing: 3)
          .font(.system(size: 13, weight: .light))
      }
      .foregroundStyle(Color.secondary)
      .padding(4)
      .background {
        RoundedRectangle(cornerRadius: 6)
          .fill(.thickMaterial)
      }
      .padding(.vertical, 5)
    }
  }
}

#Preview {
  OnitPromptView()
}
