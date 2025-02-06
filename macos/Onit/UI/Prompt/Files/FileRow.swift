//
//  FileRow.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct FileRow: View {
  var contextList: [Context]

  var body: some View {
    HStack(spacing: 6) {
      PaperclipButton()
      context
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
  }

  @ViewBuilder
  var context: some View {
    if contextList.isEmpty {
      emptyContext
    } else {
      ContextList(contextList: contextList)
    }
  }

  var emptyContext: some View {
    ContextItem(item: .file(URL(fileURLWithPath: "")))
      .opacity(0)
  }
}

#if DEBUG
  #Preview {
    ModelContainerPreview {
      FileRow(contextList: [])
    }
  }
#endif
