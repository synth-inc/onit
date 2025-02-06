//
//  RemoteModelSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import Defaults
import SwiftUI

struct RemoteModelSection: View {
    @Environment(\.model) var model
    @Environment(\.remoteModels) var remoteModels

    @State private var use = false
    @State private var key = ""
    @State private var validated = false

    @State private var loading = false

    @Default(.mode) var mode
    @Default(.remoteModel) var remoteModel
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.openAIToken) var openAIToken
    @Default(.anthropicToken) var anthropicToken
    @Default(.xAIToken) var xAIToken
    @Default(.googleAIToken) var googleAIToken
    @Default(.deepSeekToken) var deepSeekToken
    @Default(.useOpenAI) var useOpenAI
    @Default(.useAnthropic) var useAnthropic
    @Default(.useXAI) var useXAI
    @Default(.useGoogleAI) var useGoogleAI
    @Default(.useDeepSeek) var useDeepSeek
    @Default(.isOpenAITokenValidated) var isOpenAITokenValidated
    @Default(.isAnthropicTokenValidated) var isAnthropicTokenValidated
    @Default(.isXAITokenValidated) var isXAITokenValidated
    @Default(.isGoogleAITokenValidated) var isGoogleAITokenValidated
    @Default(.isDeepSeekTokenValidated) var isDeepSeekTokenValidated

    var provider: AIModel.ModelProvider

    var state: TokenValidationState.ValidationState {
        model.tokenValidation.state(for: provider)
    }

    var models: [AIModel] {
        availableRemoteModels.filter { $0.provider == provider }
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
            if remoteModels.listedModels.isEmpty {
                mode = .local
            } else {
                // If it's our first time adding models, set the remoteModel
                if remoteModel == nil {
                    remoteModel = remoteModels.listedModels.first
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
                .foregroundColor(.primary)  // Ensure placeholder text is not dimmed

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
        (Text("Add ")
            + Text(.init(link))
            + Text(
                """
                 to use Onit with \(provider.title) \
                models like \(provider.sample).
                """
            ))
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
            openAIToken = key.isEmpty ? nil : key
        case .anthropic:
            anthropicToken = key.isEmpty ? nil : key
        case .xAI:
            xAIToken = key.isEmpty ? nil : key
        case .googleAI:
            googleAIToken = key.isEmpty ? nil : key
        case .deepSeek:
            deepSeekToken = key.isEmpty ? nil : key
        case .custom:
            break  // TODO: KNA -
        }
    }

    func fetchKey() {
        switch provider {
        case .openAI:
            key = openAIToken ?? ""
        case .anthropic:
            key = anthropicToken ?? ""
        case .xAI:
            key = xAIToken ?? ""
        case .googleAI:
            key = googleAIToken ?? ""
        case .deepSeek:
            key = deepSeekToken ?? ""
        case .custom:
            break  // TODO: KNA -
        }
    }

    func checkUse() {
        switch provider {
        case .openAI:
            use = useOpenAI
        case .anthropic:
            use = useAnthropic
        case .xAI:
            use = useXAI
        case .googleAI:
            use = useGoogleAI
        case .deepSeek:
            use = useDeepSeek
        case .custom:
            break  // TODO: KNA -
        }
    }

    func checkValidated() {
        switch provider {
        case .openAI:
            validated = isOpenAITokenValidated
        case .anthropic:
            validated = isAnthropicTokenValidated
        case .xAI:
            validated = isXAITokenValidated
        case .googleAI:
            validated = isGoogleAITokenValidated
        case .deepSeek:
            validated = isDeepSeekTokenValidated
        case .custom:
            break  // TODO: KNA -
        }
    }

    func save(use: Bool) {
        switch provider {
        case .openAI:
            useOpenAI = use
        case .anthropic:
            useAnthropic = use
        case .xAI:
            useXAI = use
        case .googleAI:
            useGoogleAI = use
        case .deepSeek:
            useDeepSeek = use
        case .custom:
            break  // TODO: KNA -
        }
    }

    func save(validated: Bool) {
        switch provider {
        case .openAI:
            isOpenAITokenValidated = validated
        case .anthropic:
            isAnthropicTokenValidated = validated
        case .xAI:
            isXAITokenValidated = validated
        case .googleAI:
            isGoogleAITokenValidated = validated
        case .deepSeek:
            isDeepSeekTokenValidated = validated
        case .custom:
            break  // TODO: KNA -
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
