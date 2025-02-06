//
//  CopyButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/28/24.
//

import SwiftUI

struct CopyButton: View {
  @State var showCheckmark = false

  var text: String
  var stripMarkdown = false

  private var textToCopy: String {
    stripMarkdown ? text.stripMarkdown() : text
  }

  var body: some View {
    Button {
      let pasteboard = NSPasteboard.general
      pasteboard.declareTypes([.string], owner: nil)
      pasteboard.setString(textToCopy, forType: .string)
      showCheckmark = true

      Task {
        try await Task.sleep(for: .seconds(2))
        showCheckmark = false
      }
    } label: {
      Image(.copy)
        .renderingMode(.template)
        .padding(4)
        .opacity(showCheckmark ? 0 : 1)
        .overlay {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(Color.limeGreen)
            .opacity(showCheckmark ? 1 : 0)
        }
    }
    .tooltip(prompt: "Copy")
    .animation(.default, value: showCheckmark)
  }
}

#Preview {
  CopyButton(text: "Hello world")
}
