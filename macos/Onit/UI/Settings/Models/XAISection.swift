//
//  XAISection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct XAISection: View {
    @Environment(\.model) var model

    @State private var xAIKey: String = ""
    @State private var showXAIKey: Bool = false

    var body: some View {
        Section("xAI") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack(alignment: .trailing) {
                        if showXAIKey {
                            TextField("xAI API Key", text: $xAIKey)
                        } else {
                            SecureField("xAI API Key", text: $xAIKey)
                        }

                        Button(action: { showXAIKey.toggle() }) {
                            Image(systemName: showXAIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                        .padding(.trailing, 8)
                    }

                    Button(action: {
                        guard !xAIKey.isEmpty else { return }
                        Task {
                            await model.validateToken(provider: AIModel.ModelProvider.xAI, token: xAIKey)
                        }
                    }) {
                        switch model.tokenValidation.state(for: AIModel.ModelProvider.xAI) {
                        case .notValidated:
                            Text("Validate")
                        case .validating:
                            ProgressView()
                                .controlSize(.small)
                        case .valid:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.limeGreen)
                        case .invalid:
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .disabled(xAIKey.isEmpty || model.tokenValidation.state(for: AIModel.ModelProvider.xAI).isValidating)
                }
                if case .invalid(let error) = model.tokenValidation.state(for: .xAI) {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .onChange(of: xAIKey) { _, newValue in
                model.xAIToken = newValue.isEmpty ? nil : newValue
            }

            Text("Get your API key from [xAI](https://console.x.ai/)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if model.isXAITokenValidated {
                ForEach(AIModel.allCases.filter { $0.provider == .xAI }) { aiModel in
                    Toggle(aiModel.displayName, isOn: Binding(
                        get: { model.preferences.visibleModels.contains(aiModel) },
                        set: { isOn in
                            if isOn {
                                model.preferences.visibleModels.insert(aiModel)
                            } else {
                                model.preferences.visibleModels.remove(aiModel)
                            }
                        }
                    ))
                }
            }
        }
    }
}
