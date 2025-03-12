//
//  MenuBarLabel.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI
@_spi(Advanced) import MenuBarExtraAccess

struct MenuBarContent: View {
    @Environment(\.model) var model
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var featureFlagsManager: FeatureFlagManager
    @State private var showingHistory = false

    init() {
        self._featureFlagsManager = ObservedObject(wrappedValue: FeatureFlagManager.shared)
    }

    var body: some View {
        VStack(spacing: 5) {
            MenuCheckForPermissions()
            MenuOpenOnitButton()
            MenuHistory(isPresented: $showingHistory)
                .popover(isPresented: $showingHistory) {
                    HistoryView()
                        .modelContainer(SwiftDataContainer.appContainer)
                }
            MenuDivider()
            if featureFlagsManager.accessibility && model.accessibilityPermissionStatus == .granted
            {
                MenuAppearsInPicker()
                MenuDivider()
            }
            MenuSettings()
            MenuCheckForUpdates()
            MenuHowItWorks()
            MenuDivider()
            MenuQuit()
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 5)
    }
}

#Preview {
    MenuBarContent()
}
