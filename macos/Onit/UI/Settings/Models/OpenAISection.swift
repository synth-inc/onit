//
//  OpenAISection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import Defaults
import SwiftUI

struct OpenAISection: View {
    @Environment(\.model) var model

    @State private var openAIKey: String = ""
    @State private var showOpenAIKey: Bool = false
    
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.visibleModelIds) var visibleModelIds
    @Default(.isOpenAITokenValidated) var isOpenAITokenValidated
    @Default(.openAIToken) var openAIToken
    
    var visibleModelsList : [AIModel] {
        availableRemoteModels
            .filter { visibleModelIds.contains($0.id) }
            .filter { $0.provider == .openAI }
    }

    var body: some View {
        Section("OpenAI") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack(alignment: .trailing) {
                        if showOpenAIKey {
                            TextField("OpenAI API Key", text: $openAIKey)
                        } else {
                            SecureField("OpenAI API Key", text: $openAIKey)
                        }

                        Button(action: { showOpenAIKey.toggle() }) {
                            Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                        .padding(.trailing, 8)
                    }

                    Button(action: {
                        guard !openAIKey.isEmpty else { return }
                        Task {
                            await model.validateToken(provider: AIModel.ModelProvider.openAI, token: openAIKey)
                        }
                    }) {
                        switch model.tokenValidation.state(for: AIModel.ModelProvider.openAI) {
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
                    .disabled(openAIKey.isEmpty || model.tokenValidation.state(for: AIModel.ModelProvider.openAI).isValidating)
                }

                if case .invalid(let error) = model.tokenValidation.state(for: .openAI) {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .onChange(of: openAIKey) { _, newValue in
                openAIToken = newValue.isEmpty ? nil : newValue
            }

            Text("Get your API key from [OpenAI](https://platform.openai.com/api-keys)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if isOpenAITokenValidated {
                ForEach(visibleModelsList) { aiModel in
                    ModelToggle(aiModel: aiModel)
                }
            }
        }
        .onAppear {
            openAIKey = openAIToken ?? ""
        }
    }
}

#Preview {
    OpenAISection()
}
