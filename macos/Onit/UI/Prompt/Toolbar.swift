//
//  Toolbar.swift
//  Omni
//
//  Created by Benjamin Sage on 9/20/24.
//

import SwiftUI
import KeyboardShortcuts

struct Toolbar: View {
    @Environment(\.model) var model

    var body: some View {
        HStack(spacing: 4) {
            esc
            resize
            Spacer()
            languageModel
            localMode
//            incognitoMode
            settings
        }
        .foregroundStyle(.gray200)
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
        .background {
            escListener
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
        .tooltip(prompt: "Close Omni", shortcut: .text("ESC ESC"))
    }

    // We create this so that the esc button has a different
    // effect when clicked vs keyboard shortcut
    var escListener: some View {
        Button {
            switch model.generationState {
            case .idle:
                model.closePanel()
            default:
                model.generationState = .idle
                model.textFocusTrigger.toggle()
                model.youSaid = nil
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.escape, modifiers: [])
    }

    var resize: some View {
        Button {

        } label: {
            Image(.resize)
                .renderingMode(.template)
                .padding(3)
        }
        .tooltip(
            prompt: "Resize Window",
            shortcut: .keyboard(.init("1", modifiers: .option))
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
            model.showModelSelectionOverlay()
        } label: {
            HStack(spacing: 0) {
                Text(model.preferences.mode == .local ?
                     (model.preferences.localModel?.split(separator: ":").first.map(String.init) ?? "") :
                     (model.preferences.model?.displayName ?? ""))
                    .appFont(.medium13)
                    .padding(.leading, 2)
                Image(.smallChevDown)
                    .renderingMode(.template)
            }
            .padding(2)
            .contentShape(.rect)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(model.modelSelectionWindowController == nil ? Color.clear : .gray800)
            }
        }
        .buttonStyle(.plain)
        .tooltip(prompt: "Toggle model", shortcut: .keyboard(.init("/")))
    }

    var add: some View {
        Button {
            model.newPrompt()
        } label: {
            Image(.circlePlus)
                .renderingMode(.template)
                .padding(2)
        }
        .tooltip(prompt: "New Prompt")
    }

    var localMode: some View {
        Button {
            model.updatePreferences { prefs in
                prefs.mode = prefs.mode == .local ? .remote : .local
            }
        } label: {
            Image(model.preferences.mode == .local ? .localModeActive : .localMode)
                .renderingMode(.template)
                .padding(2)
                .foregroundColor(model.preferences.mode == .local ? .limeGreen : .gray200)
        }
        .tooltip(prompt: "Local Mode")
    }
    
    var incognitoMode: some View {
        Button {
            model.incognitoMode.toggle()
        } label: {
            Image(model.incognitoMode ? .incognitoModeActive : .incognitoMode)
                .renderingMode(.template)
                .padding(2)
                .foregroundColor(model.incognitoMode ? .limeGreen : .gray200)
        }
        .tooltip(prompt: "Incognito Mode")
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
        .tooltip(prompt: "Settings", shortcut: .keyboard(.init(",")))
    }
}

#Preview {
    Toolbar()
}
