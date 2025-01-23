//
//  GoogleAISection.swift
//  Onit
//

import SwiftUI

struct GoogleAISection: View {
    @Environment(\.model) var model

    @State private var googleAIKey: String = ""
    @State private var showGoogleAIKey: Bool = false

    var body: some View {
        Section("Google AI") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack(alignment: .trailing) {
                        if showGoogleAIKey {
                            TextField("Google AI API Key", text: $googleAIKey)
                        } else {
                            SecureField("Google AI API Key", text: $googleAIKey)
                        }

                        Button(action: { showGoogleAIKey.toggle() }) {
                            Image(systemName: showGoogleAIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                        .padding(.trailing, 8)
                    }

                    Button(action: {
                        guard !googleAIKey.isEmpty else { return }
                        Task {
                            await model.validateToken(provider: AIModel.ModelProvider.googleAI, token: googleAIKey)
                        }
                    }) {
                        switch model.tokenValidation.state(for: AIModel.ModelProvider.googleAI) {
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
                    .disabled(googleAIKey.isEmpty || model.tokenValidation.state(for: AIModel.ModelProvider.googleAI).isValidating)
                }

                if case .invalid(let error) = model.tokenValidation.state(for: .googleAI) {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .onChange(of: googleAIKey) { _, newValue in
                model.googleAIToken = newValue.isEmpty ? nil : newValue
            }

            Text("Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if model.isGoogleAITokenValidated {
                ForEach(model.preferences.visibleModelsList.filter { $0.provider == .googleAI }) { aiModel in
                    ModelToggle(aiModel: aiModel)
                }
            }
        }
        .onAppear {
            googleAIKey = model.googleAIToken ?? ""
        }
    }
}

#Preview {
    GoogleAISection()
}