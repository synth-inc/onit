//
//  GeneratingView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import SwiftUI

struct GeneratingView: View {
    @Environment(\.model) var model

    var delete: KeyboardShortcut {
        .init(.delete, modifiers: [.command])
    }

    var body: some View {
        Button {
            model.cancelGenerate()
            model.textFocusTrigger.toggle()
        } label: {
            VStack(spacing: 12) {
                icon
                text
            }
            .padding(20)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.delete)
    }

    var icon: some View {
        Image(.word)
            .shimmering()
    }

    var text: some View {
        HStack(spacing: 4) {
            Text("Cancel")
                .foregroundStyle(.gray200)
            KeyboardShortcutView(shortcut: delete)
                .foregroundStyle(.gray300)
        }
        .appFont(.medium13)
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        GeneratingView()
    }
}
#endif
