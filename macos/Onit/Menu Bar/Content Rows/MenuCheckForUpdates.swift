//
//  MenuCheckForUpdates.swift
//  Onit
//
//  Created by Benjamin Sage on 10/11/24.
//

import SwiftUI
import Sparkle
import Defaults

struct MenuCheckForUpdates: View {
    @Environment(\.model) var model
    @State var checkUpdates: CheckForUpdatesViewModel?
    @State private var showUpdateError = false
    
    var disabled: Bool {
        guard let checkUpdates else { return false }
        return !checkUpdates.canCheckForUpdates
    }
    
    var body: some View {
        MenuBarRow {
            if FeatureFlagManager.shared.showLegacyClientCantUpdateDialog {
                showUpdateError = true
            } else {
                model.updater.updater.checkForUpdates()
            }
        } leading: {
            Text("Check for updates...")
                .padding(.horizontal, 10)
        } trailing: {
            
        }
        .disabled(disabled)
        .task {
            checkUpdates = CheckForUpdatesViewModel(updater: model.updater.updater)
        }
        .alert("Update Not Available", isPresented: $showUpdateError) {
            Button("Download New Version") {
                if let url = URL(string: "https://www.getonit.ai") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your version of Onit can't be updated automatically. To get the latest, please delete this version and download a new version from our website.")
        }
    }
}

#Preview {
    MenuCheckForUpdates()
}
