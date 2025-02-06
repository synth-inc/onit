//
//  MenuQuit.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuQuit: View {
  var shortcut: KeyboardShortcut {
    KeyboardShortcut("q")
  }

  var body: some View {
    MenuBarRow {
      NSApplication.shared.terminate(nil)
    } leading: {
      Text("Quit Onit Completely")
        .padding(.leading, 10)
    } trailing: {
      KeyboardShortcutView(shortcut: shortcut)
        .padding(.trailing, 10)
    }
    .keyboardShortcut("q")
  }
}

#Preview {
  MenuQuit()
}
