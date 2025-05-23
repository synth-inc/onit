//
//  TypeAheadUndoView.swift
//  Onit
//
//  Created by Kévin Naudin on 21/02/2025.
//

import KeyboardShortcuts
import SwiftUI

struct TypeAheadUndoView: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings
    
    private var shortcut: KeyboardShortcut? {
        let shortcut = KeyboardShortcuts.Shortcut(.z, modifiers: [.command])
        let name = KeyboardShortcuts.Name("undo", default: shortcut)
        
        return KeyboardShortcuts.getShortcut(for: name)?.native
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text("Undo auto-complete")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray200)
            KeyboardShortcutView(shortcut: shortcut, characterWidth: 12, spacing: 3)
                .font(.system(size: 12, weight: .light))
                .padding(4)
                .foregroundStyle(.white)
                .background(RoundedRectangle(cornerRadius: 6).fill(.gray400))
            Button {
                appState.setSettingsTab(tab: .typeahead)
                openSettings()
            } label: {
                Image(.settingsCog)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.gray200)
                    .frame(width: 20, height: 20)
            }
            .padding(.leading, 4)
            .buttonStyle(.plain)
        }
        .frame(minHeight: 30)
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.typeAheadBG)
                .stroke(.gray500, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    TypeAheadUndoView()
}
