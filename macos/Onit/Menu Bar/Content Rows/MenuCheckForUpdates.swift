//
//  MenuCheckForUpdates.swift
//  Onit
//
//  Created by Benjamin Sage on 10/11/24.
//

import Sparkle
import SwiftUI

struct MenuCheckForUpdates: View {
    @Environment(\.appState) var appState
    @State var checkUpdates: CheckForUpdatesViewModel?

    var disabled: Bool {
        guard let checkUpdates else { return false }
        return !checkUpdates.canCheckForUpdates
    }

    var body: some View {
        MenuBarRow {
            appState?.updater.updater.checkForUpdates()
        } leading: {
            Text("Check for updates...")
                .padding(.horizontal, 10)
        } trailing: {

        }
        .disabled(disabled)
        .task {
            if let appState = appState {
                checkUpdates = CheckForUpdatesViewModel(updater: appState.updater.updater)
            }
        }
    }
}

#Preview {
    MenuCheckForUpdates()
}
