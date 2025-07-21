//
//  MenuBarRow.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuBarRow<Leading: View, Trailing: View>: View {
    @Environment(\.appState) var appState

    var action: () -> Void
    var leading: Leading
    var trailing: Trailing

    init(
        action: @escaping () -> Void,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.action = action
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        Button {
            action()
            if let appState = appState {
                @Bindable var appState = appState
                appState.showMenuBarExtra = false
            }
        } label: {
            label
        }
        .buttonStyle(MenuButtonStyle())
    }

    var label: some View {
        HStack {
            leading
            Spacer()
            trailing
                .foregroundStyle(Color.primary.opacity(0.25))
        }
        .font(.system(size: 13, weight: .medium))
        .frame(height: 22)
    }
}

#Preview {
    MenuBarRow {

    } leading: {
        Text("Hello world")
    } trailing: {
        Text("Cmd-O")
    }
}
