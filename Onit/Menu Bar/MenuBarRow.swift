//
//  MenuBarRow.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuBarRow<Leading: View, Trailing: View>: View {
    var action: () -> Void
    var leading: Leading
    var trailing: Trailing

    init(
        action: @escaping () -> Void,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.action = action
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                leading
                Spacer()
                trailing
                    .foregroundStyle(Color.primary.opacity(0.25))
            }
            .font(.system(size: 13, weight: .medium))
            .frame(height: 22)
        }
        .buttonStyle(MenuButtonStyle())
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
