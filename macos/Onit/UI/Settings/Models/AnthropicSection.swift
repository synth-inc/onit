//
//  AnthropicSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import Defaults
import SwiftUI

struct AnthropicSection: View {
    @Environment(\.model) var model

    @State private var anthropicKey: String = ""
    @State private var showAnthropicKey: Bool = false

    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.visibleModelIds) var visibleModelIds
    @Default(.isAnthropicTokenValidated) var isAnthropicTokenValidated
    @Default(.anthropicToken) var anthropicToken

    var visibleModelsList: [AIModel] {
        availableRemoteModels
            .filter { visibleModelIds.contains($0.id) }
            .filter { $0.provider == .anthropic }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack(alignment: .trailing) {
                    if showAnthropicKey {
                        TextField("Anthropic API Key", text: $anthropicKey)
                    } else {
                        SecureField("Anthropic API Key", text: $anthropicKey)
                    }

                    Button(action: { showAnthropicKey.toggle() }) {
                        Image(systemName: showAnthropicKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                    .padding(.trailing, 8)
                }

                Button(action: {
                    guard !anthropicKey.isEmpty else { return }
                    Task {
                        await model.validateToken(
                            provider: AIModel.ModelProvider.anthropic, token: anthropicKey)
                    }
                }) {
                    switch model.tokenValidation.state(for: AIModel.ModelProvider.anthropic) {
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
                .disabled(
                    anthropicKey.isEmpty
                        || model.tokenValidation.state(for: AIModel.ModelProvider.anthropic)
                            .isValidating
                )
            }
            if case .invalid(let error) = model.tokenValidation.state(for: .openAI) {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onChange(of: anthropicKey) { _, newValue in
            anthropicToken = newValue.isEmpty ? nil : newValue
        }
        .onAppear {
            anthropicKey = anthropicToken ?? ""
        }

        Text("Get your API key from [Anthropic](https://console.anthropic.com/settings/keys)")
            .font(.caption)
            .foregroundStyle(.secondary)

        if isAnthropicTokenValidated {
            ForEach(visibleModelsList) { aiModel in
                ModelToggle(aiModel: aiModel)
            }
        }
    }

    var title: some View {
        HStack {
            Text("Anthropic")
                .font(.system(size: 13))
            Spacer()
            Toggle("", isOn: .constant(false))
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }
}

#Preview {
    AnthropicSection()
}
