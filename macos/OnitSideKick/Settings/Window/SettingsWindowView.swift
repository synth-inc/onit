//
//  SettingsWindowView.swift
//  Onit
//
//  Created by Loyd Kim on 9/2/25.
//

import Defaults
import SwiftData
import SwiftUI

struct SettingsWindowView: View {
    // MARK: - Observations

    @ObservedObject private var localization = LocalizationManager.shared
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            SettingsWindowSidebar()
            SettingsWindowPages()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.S_7)
        .cornerRadius(20)
        .ignoresSafeArea(.container, edges: .top)
        .id(localization.currentLanguage)
        // The settings window is hosted in a plain NSWindow (CenteredWindow),
        // so it doesn't inherit any SwiftData container. Inject the shared app
        // container — the same instance the panels use (state.container) — so
        // @Query / modelContext work on the Prompts page (and any other
        // SwiftData-backed settings page).
        .modelContainer(SwiftDataContainer.appContainer)
    }
}
