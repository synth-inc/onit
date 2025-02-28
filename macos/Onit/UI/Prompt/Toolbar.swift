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
    @Environment(\.model) var model

    @Default(.mode) var mode
    @Default(.remoteModel) var remoteModel
    @Default(.localModel) var localModel

    var body: some View {
        HStack(spacing: 4) {
            esc
            add
            Spacer()
            languageModel
            localMode
            settings
            resize
        }
        .foregroundStyle(.gray200)
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
        .background {
            escListener
        }
        .background {
            heightListener
        }
    }

    var esc: some View {
        Button {
            model.closePanel()
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
            model.togglePanelSize()
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
        @Bindable var model = model

        Button {
            OverlayManager.shared.showOverlay(model: model, content: ModelSelectionView())
        } label: {
            HStack(spacing: 0) {
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

    var add: some View {
        HStack(spacing: 0) {
            Button {
                model.newChat()
            } label: {
                Image(.circlePlus)
                    .renderingMode(.template)
                    .padding(2)
            }
            .tooltip(prompt: "New Chat", shortcut: .keyboardShortcuts(.newChat))
            
            Button {
                model.newChat()
                
                SystemPromptState.shared.shouldShowSelection = true
                SystemPromptState.shared.shouldShowSystemPrompt = true
            } label: {
                Image(.smallChevDown)
                    .renderingMode(.template)
                    .padding(2)
            }
            .onHover(perform: { isHovered in
                if isHovered && model.currentChat?.systemPrompt == nil && !SystemPromptState.shared.shouldShowSystemPrompt {
                    SystemPromptState.shared.shouldShowSystemPrompt = true
                }
            })
            .tooltip(prompt: "Start new Chat with system prompt")
        }
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

    var history: some View {
        Button {
            model.showHistory = true
        } label: {
            Image(.history)
                .renderingMode(.template)
                .padding(2)
        }
        .tooltip(prompt: "History")
    }

    @Environment(\.openSettings) var openSettings
    var settings: some View {
        Button {
            NSApp.activate()
            if NSApp.isActive {
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
                    model.headerHeight = proxy.size.height
                }
                .onChange(of: proxy.size.height) { _, new in
                    model.headerHeight = new
                }
        }
    }
}

#Preview {
    Toolbar()
}
