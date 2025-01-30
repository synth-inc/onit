//
//  RemoteModelSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct RemoteModelSection: View {
    @Environment(\.model) var model

    @State private var use = false
    @State private var key = ""
    @State private var validated = false

    @State private var loading = false

    var provider: AIModel.ModelProvider

    var state: TokenValidationState.ValidationState {
        model.tokenValidation.state(for: provider)
    }

    var models: [AIModel] {
        model.preferences.availableRemoteModels.filter { $0.provider == provider }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            titleView
            textField
            errorView
            caption
            modelsView
        }
        .onAppear {
            fetchKey()
            checkValidated()
            checkUse()
        }
        .onChange(of: state) {
            updateUse()
        }
        .onChange(of: use) {
            save(use: use)
            save(validated: validated)
            // If we've turned off everything go into local mode.
            if model.listedModels.isEmpty {
                model.preferences.mode = .local
            } else {
                // If it's our first time adding models, set the remoteModel
                if model.preferences.remoteModel == nil {
                    model.preferences.remoteModel = model.listedModels.first
                }
            }
            // This will collapse SetupDialogs if they're no longer needed
            model.shrinkContent()
        }
    }

    // MARK: - Subviews

    var titleView: some View {
        ModelTitle(title: provider.title, isOn: $use, showToggle: $validated)
            // .disabled(!validated)
    }

    var textField: some View {
        HStack(spacing: 7) {
            TextField("Enter your \(provider.title) API key", text: $key)
                .textFieldStyle(.roundedBorder)
                .frame(height: 22)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary) // Ensure placeholder text is not dimmed

            Button {
                Task {
                    loading = true
                    save(key: key)
                    model.tokenValidation.setNotValidated(provider: provider)
                    model.setTokenIsValid(false, provider: provider)
                    await validate()
                    loading = false
                }
            } label: {
                if validated {
                    Text("Verified")
                } else {
                    buttonOverlay
                }
            }
            .disabled(state.isValidating)
            .foregroundStyle(.white)
            .buttonStyle(.borderedProminent)
            .frame(height: 22)
            .fontWeight(.regular)
        }
        .font(.system(size: 13).weight(.regular))
    }

    @ViewBuilder
    var buttonOverlay: some View {
        switch state {
        case .notValidated, .invalid:
            Text("Verify →")
        case .validating:
            ProgressView()
                .controlSize(.small)
        case .valid:
            if validated {
                Text("Verified")
            } else {
                Text("Verify →")
            }
        }
    }

    @ViewBuilder
    var errorView: some View {
        if case .invalid(let error) = state {
            HStack(spacing: 8) {
                Image(.warningSettings)
                Text(error.localizedDescription)
                    .opacity(0.65)
                    .fontWeight(.regular)
                    .font(.system(size: 12))
            }
        }
    }

    var link: String {
        "[your \(provider.title) key](\(provider.url))"
    }

    var caption: some View {
        (
            Text("Add ")
            +
            Text(.init(link))
            +
            Text("""
                 to use Onit with \(provider.title) \
                models like \(provider.sample).
                """
            )
        )
        .foregroundStyle(.foreground.opacity(0.65))
        .fontWeight(.regular)
        .font(.system(size: 12))
    }

    @ViewBuilder
    var modelsView: some View {
        if use {
            GroupBox {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(models) { model in
                        ModelToggle(aiModel: model)
                            .frame(height: 36)
                    }
                }
                .padding(.vertical, -4)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Functions

    func validate() async {
        await model.validateToken(provider: provider, token: key)
    }

    func save(key: String) {
        switch provider {
        case .openAI:
            model.openAIToken = key.isEmpty ? nil : key
        case .anthropic:
            model.anthropicToken = key.isEmpty ? nil : key
        case .xAI:
            model.xAIToken = key.isEmpty ? nil : key
        case .googleAI:
            model.googleAIToken = key.isEmpty ? nil : key
        }
        
    }

    func fetchKey() {
        switch provider {
        case .openAI:
            key = model.openAIToken ?? ""
        case .anthropic:
            key = model.anthropicToken ?? ""
        case .xAI:
            key = model.xAIToken ?? ""
        case .googleAI:
            key = model.googleAIToken ?? ""
        }
    }

    func checkUse() {
        switch provider {
        case .openAI:
            use = model.useOpenAI
        case .anthropic:
            use = model.useAnthropic
        case .xAI:
            use = model.useXAI
        case .googleAI:
            use = model.useGoogleAI
        }
    }

    func checkValidated() {
        switch provider {
        case .openAI:
            validated = model.isOpenAITokenValidated
        case .anthropic:
            validated = model.isAnthropicTokenValidated
        case .xAI:
            validated = model.isXAITokenValidated
        case .googleAI:
            validated = model.isGoogleAITokenValidated
        }
    }

    func save(use: Bool) {
        switch provider {
        case .openAI:
            model.useOpenAI = use
        case .anthropic:
            model.useAnthropic = use
        case .xAI:
            model.useXAI = use
        case .googleAI:
            model.useGoogleAI = use
        }
    }

    func save(validated: Bool) {
        switch provider {
        case .openAI:
            model.isOpenAITokenValidated = validated
        case .anthropic:
            model.isAnthropicTokenValidated = validated
        case .xAI:
            model.isXAITokenValidated = validated
        case .googleAI:
            model.isGoogleAITokenValidated = validated
        }
    }

    func updateUse() {
        if state == .valid {
            use = true
            validated = true
        } else if case .invalid(_) = state {
            use = false
            validated = false
        }
    }
}
