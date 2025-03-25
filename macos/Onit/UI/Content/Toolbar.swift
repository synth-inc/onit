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
    @Default(.remoteModel) var remoteModel
    @Default(.localModel) var localModel
    @Default(.isRegularApp) var isRegularApp

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if !isRegularApp {
                esc
                ToolbarAddButton()
                Spacer()
            }
            
            languageModel
            localMode
            history
            settings
            
            if !isRegularApp {
                resize
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.gray200)
        .padding(.horizontal, isRegularApp ? 0 : 14)
        .padding(.vertical, isRegularApp ? 0 : 2)
        .background {
            escListener
        }
        .background {
            heightListener
        }
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

    var resize: some View {
        Button {
            state.panel?.toggleFullscreen()
        } label: {
            Image(.resize)
                .renderingMode(.template)
                .padding(3)
        }
        .tooltip(
            prompt: "Resize Window",
            shortcut: .keyboardShortcuts(.resizeWindow)
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

    @ViewBuilder
    var languageModel: some View {
        Button {
            OverlayManager.shared.captureClickPosition()
            
            let view = ModelSelectionView()
                .environment(\.appState, appState)
                .environment(\.windowState, state)
            
            OverlayManager.shared.showOverlay(content: view)
        } label: {
            HStack(spacing: 0) {
                Spacer()
                Text(
                    mode == .local
                        ? (localModel?.split(separator: ":").first.map(String.init)
                            ?? "Choose model")
                        : (remoteModel?.displayName ?? "Choose model")
                )
                .appFont(.medium13)
                .padding(.leading, 2)
                Image(.smallChevDown)
                    .renderingMode(.template)
            }
            .padding(2)
            .contentShape(.rect)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
            }
        }
        .tooltip(prompt: "Change model")
    }

    var localMode: some View {
        Button {
            mode = mode == .local ? .remote : .local
        } label: {
            Image(mode == .local ? .localModeActive : .localMode)
                .renderingMode(.template)
                .padding(2)
                .foregroundColor(mode == .local ? .limeGreen : .gray200)
        }
        .tooltip(prompt: "Local Mode", shortcut: .keyboardShortcuts(.toggleLocalMode))
    }

    var showHistoryBinding: Binding<Bool> {
        Binding(
            get: { self.state.showHistory },
            set: { self.state.showHistory = $0 }
        )
    }
    
    var history: some View {
        Button {
            state.showHistory.toggle()
        } label: {
            Image(.history)
                .renderingMode(.template)
                .padding(2)
        }
        .tooltip(prompt: "History")
        .popover(
            isPresented: showHistoryBinding,
            arrowEdge: .bottom
        )  {
            HistoryView()
        }
    }

    var settings: some View {
        Button {
            NSApp.activate()
            if NSApp.isActive {
                appState.setSettingsTab(tab: .general)
                openSettings()
            }
        } label: {
            Image(.settingsCog)
                .renderingMode(.template)
                .padding(2)
        }
        .tooltip(prompt: "Settings", shortcut: .none)
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
}

#Preview {
    Toolbar()
}
