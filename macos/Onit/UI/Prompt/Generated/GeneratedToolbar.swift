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
            selector
            insert
        }
        .foregroundStyle(.FG)
    }

    @ViewBuilder
    var copy: some View {
        if let generation = model.generation {
            CopyButton(text: generation)
        }
    }

    var regenerate: some View {
        Button {
            model.save(model.instructions)
            model.generate(model.instructions)
        } label: {
            Image(.arrowsSpin)
                .padding(4)
        }
        .tooltip(prompt: "Retry")
    }

    var more: some View {
        Button {

        } label: {
            Image(.moreHorizontal)
                .padding(4)
        }
        .tooltip(prompt: "More")
    }

    @ViewBuilder
    var selector: some View {
        if let count = model.generationCount, count > 1 {
            ToggleOutputsView()
                .padding(.trailing, 8)
        }
    }

    var insertShortcut: KeyboardShortcut {
        .init("y")
    }

    var insert: some View {
        Button {
            if let text = model.generation {
                Accessibility.insertText(text)
                model.closePanel()
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
                    .fill(model.preferences.mode == .local ? .green : .blue400)
            }
            .foregroundStyle(.FG)
        }
        .keyboardShortcut(insertShortcut)
        .buttonStyle(.plain)
        .tooltip(
            prompt: "Send",
            shortcut: .keyboard(.init(.return, modifiers: [])),
            background: false
        )
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        GeneratedToolbar()
            .padding()
    }
}
#endif
