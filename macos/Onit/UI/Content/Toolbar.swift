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
    @Default(.isRegularApp) var isRegularApp

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if !isRegularApp {
                esc
                ToolbarAddButton()
                Spacer()
            }
            
            localMode
            history
            settings
            
            if !isRegularApp { resize }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 32, alignment: .center)
        .foregroundStyle(.gray200)
        .padding(.horizontal, isRegularApp ? 0 : 12)
        .background { escListener }
        .background { heightListener }
    }

    var esc: some View {
        Button {
            state.closePanel()
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
    
    var heightListener: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    state.headerHeight = proxy.size.height
                }
                .onChange(of: proxy.size.height) { _, new in
                    state.headerHeight = new
                }
        }
    }

    var resize: some View {
        IconButton(
            icon: .resize,
            action: { state.panel?.toggleFullscreen() },
            tooltipPrompt: "Resize Window",
            tooltipShortcut: .keyboardShortcuts(.resizeWindow)
        )
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
            action: { openSettingsWindow() },
            tooltipPrompt: "Settings"
        )
    }
}

#Preview {
    Toolbar()
}
