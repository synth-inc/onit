//
//  MenuCheckForUpdates.swift
//  Onit
//
//  Created by Benjamin Sage on 10/11/24.
//

import SwiftUI
import Sparkle

struct MenuCheckForUpdates: View {
    @Environment(\.model) var model
    @State var checkUpdates: CheckForUpdatesViewModel?

    var disabled: Bool {
        guard let checkUpdates else { return false }
        return !checkUpdates.canCheckForUpdates
    }

    var body: some View {
        MenuBarRow {
            model.updater.updater.checkForUpdates()
        } leading: {
            Text("Check for updates...")
                .padding(.horizontal, 10)
        } trailing: {

        }
        .disabled(disabled)
        .task {
            checkUpdates = CheckForUpdatesViewModel(updater: model.updater.updater)
        }
    }
}

#Preview {
    MenuCheckForUpdates()
}
