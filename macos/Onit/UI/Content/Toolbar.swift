//
//  Toolbar.swift
//  Onit
//
//  Created by Benjamin Sage on 9/20/24.
//

import Defaults
import KeyboardShortcuts
import SwiftUI

struct Toolbar: View {
    @Environment(\.appState) private var appState
    @Environment(\.openSettings) var openSettings
    @Environment(\.windowState) private var state
    
    @Default(.mode) var mode

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            localMode
            history
            settings
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 32, alignment: .center)
        .foregroundStyle(.gray200)
        .padding(.horizontal, 0)
        .background { escListener }
    }

    var esc: some View {
        Button {
            PanelStateCoordinator.shared.closePanel(for: state)
        } label: {
            Text("ESC")
                .appFont(.medium13)
                .padding(4)
        }
        .tooltip(prompt: "Close Onit", shortcut: .keyboardShortcuts(.escape))
    }

    // Empty view for layout purposes
    var escListener: some View {
        EmptyView()
    }

    // Helper function to create a picker for models
    private func createModelPicker<T: Hashable>(
        title: String,
        selection: Binding<T?>,
        models: [T],
        currentModel: T?
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(models, id: \.self) { model in
                HStack {
                    Text("\(model)")
                    Spacer()
                    if model == currentModel {
                        Text("default")
                            .italic()
                            .foregroundStyle(.gray400)
                    }
                }
                .tag(model as T?)
            }
        }
        .pickerStyle(.inline)
    }

    func toggleMode() {
        mode = mode == .local ? .remote : .local
    }
    var localMode: some View {
        IconButton(
            icon: mode == .local ? .localModeActive : .localMode,
            iconSize: 22,
            action: { toggleMode() },
            isActive: mode == .local,
            activeColor: .limeGreen,
            tooltipPrompt: "Local Mode",
            tooltipShortcut: .keyboardShortcuts(.toggleLocalMode)
        )
    }

    var showHistoryBinding: Binding<Bool> {
        Binding(
            get: { self.state.showHistory },
            set: { self.state.showHistory = $0 }
        )
    }
    var history: some View {
        IconButton(
            icon: .history,
            iconSize: 22,
            action: { state.showHistory.toggle() },
            isActive: state.showHistory,
            tooltipPrompt: "History"
        )
        .popover(
            isPresented: showHistoryBinding,
            arrowEdge: .bottom
        )  {
            HistoryView()
        }
    }

    func openSettingsWindow() {
        NSApp.activate()
        if NSApp.isActive {
            appState.setSettingsTab(tab: .general)
            openSettings()
        }
    }
    var settings: some View {
        IconButton(
            icon: .settingsCog,
            iconSize: 22,
            action: { openSettingsWindow() },
            tooltipPrompt: "Settings"
        )
    }
}

#Preview {
    Toolbar()
}
