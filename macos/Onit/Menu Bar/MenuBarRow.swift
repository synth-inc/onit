//
//  MenuBarRow.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuBarRow<Leading: View, Trailing: View>: View {
    @Environment(\.model) var model

    var type: MenuBarRowType
    var leading: Leading
    var trailing: Trailing

    init(
        action: @escaping () -> Void,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.type = .button(action)
        self.leading = leading()
        self.trailing = trailing()
    }

    init(
        _ type: MenuBarRowType,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.type = type
        self.leading = leading()
        self.trailing = trailing()
    }

    enum MenuBarRowType {
        case button(() -> Void)
        case settings
    }

    var body: some View {
        switch type {
        case .button(let action):
            Button {
                action()
                @Bindable var model = model
                model.showMenuBarExtra = false
            } label: {
                label
            }
            .buttonStyle(MenuButtonStyle())
        case .settings:
            SettingsLink {
                label
            }
            .buttonStyle(MenuButtonStyle())
        }
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
