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
            incognitoMode
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
                if model.input == nil {
                    model.closePanel()
                } else {
                    @Bindable var model = model
                    model.input = nil
                }
            default:
                model.generationState = .idle
                model.textFocusTrigger.toggle()
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

    @ViewBuilder
    var languageModel: some View {
        @Bindable var model = model

        Menu {
            Picker("Remote model", selection: Binding(
                get: { model.preferences.mode == .remote ? model.preferences.model : nil },
                set: { newValue in
                    model.preferences.model = newValue
                    model.preferences.mode = .remote
                }
            )) {
                ForEach(model.preferences.visibleModelsList) { model in
                    HStack {
                        Text(model.displayName)
                        Spacer()
                        if model == model.preferences.model {
                            Text("default")
                                .italic()
                                .foregroundStyle(.gray400)
                        }
                    }
                    .tag(model)
                }
            }
            .pickerStyle(.inline)
            
            Picker("Local model", selection: Binding(
                get: { model.preferences.mode == .local ? model.preferences.localModel : nil },
                set: { newValue in
                    model.preferences.localModel = newValue
                    model.preferences.mode = .local
                }
            )) {
                ForEach(model.availableLocalModels, id: \.self) { modelName in
                    HStack {
                        Text(modelName)
                        Spacer()
                        if modelName == model.preferences.localModel {
                            Text("default")
                                .italic()
                                .foregroundStyle(.gray400)
                        }
                    }
                    .tag(modelName as String?)
                }
            }
            .pickerStyle(.inline)
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
        }
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
            model.preferences.mode = model.preferences.mode == .local ? .remote : .local
        } label: {
            Image(model.preferences.mode == .local ? .localModeActive : .localMode)
                .renderingMode(.template)
                .padding(2)
                .foregroundColor(model.preferences.mode == .local ? .green : .gray200)
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
                .foregroundColor(model.incognitoMode ? .green : .gray200)
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
