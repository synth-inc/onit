//
//  GeneratedToolbar.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import SwiftUI

struct GeneratedToolbar: View {
    @Environment(\.model) var model

    var body: some View {
        HStack(spacing: 8) {
            copy
            regenerate
            more
            Spacer()
            insert
        }
        .buttonStyle(HoverableButtonStyle())
    }

    var copy: some View {
        Button {

        } label: {
            Image(.copy)
                .padding(4)
        }
    }

    var regenerate: some View {
        Button {

        } label: {
            Image(.arrowsSpin)
                .padding(4)
        }
    }

    var more: some View {
        Button {

        } label: {
            Image(.moreHorizontal)
                .padding(4)
        }
    }

    var insertShortcut: KeyboardShortcut {
        .init("y")
    }

    var insert: some View {
        Button {
            if case let .generated(text) = model.generationState {
                Accessibility.insertText(text)
            } else {
                print("Not generated: \(model.generationState)")
            }
        } label: {
            HStack(spacing: 4) {
                Text("Insert")
                    .appFont(.medium14)
                    .padding(.leading, 4)
                KeyboardShortcutView(shortcut: insertShortcut)
                    .appFont(.medium12)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 5)
                    .background {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(.blue350)
                    }
            }
            .padding(4)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.blue400)
            }
            .foregroundStyle(.FG)
        }
        .keyboardShortcut(insertShortcut)
        .buttonStyle(.plain)
    }
}

#Preview {
    GeneratedToolbar()
        .padding()
        .environment(Model())
}
