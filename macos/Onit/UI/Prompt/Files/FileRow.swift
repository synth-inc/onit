//
//  FileRow.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct FileRow: View {
    @Environment(\.model) var model

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
        if model.context.isEmpty {
            emptyContext
        } else {
            ContextList()
        }
    }

    var emptyContext: some View {
        ContextItem(item: URL(fileURLWithPath: ""))
            .opacity(0)
            .overlay(alignment: .leading) {
                Text("Add file")
                    .foregroundStyle(.gray200)
                    .appFont(.medium13)
            }
    }
}

#Preview {
    FileRow()
        .environment(OnitModel())
}
