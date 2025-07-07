//
//  RemoteModelSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import Defaults
import SwiftUI

struct RemoteModelSection: View {
    @Environment(\.appState) var appState

    @State private var use = false
    @State private var key = ""
    @State private var validated = false
    @State private var loading = false
    @State private var showAdvanced: Bool = false  
    @State private var localState: TokenValidationState.ValidationState = .notValidated

    @Default(.mode) var mode
    @Default(.remoteModel) var remoteModel
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.openAIToken) var openAIToken
    @Default(.anthropicToken) var anthropicToken
    @Default(.xAIToken) var xAIToken
    @Default(.googleAIToken) var googleAIToken
    @Default(.deepSeekToken) var deepSeekToken
    @Default(.perplexityToken) var perplexityToken
    @Default(.useOpenAI) var useOpenAI
    @Default(.useAnthropic) var useAnthropic
    @Default(.useXAI) var useXAI
    @Default(.useGoogleAI) var useGoogleAI
    @Default(.useDeepSeek) var useDeepSeek
    @Default(.usePerplexity) var usePerplexity
    @Default(.isOpenAITokenValidated) var isOpenAITokenValidated
    @Default(.isAnthropicTokenValidated) var isAnthropicTokenValidated
    @Default(.isXAITokenValidated) var isXAITokenValidated
    @Default(.isGoogleAITokenValidated) var isGoogleAITokenValidated
    @Default(.isDeepSeekTokenValidated) var isDeepSeekTokenValidated
    @Default(.isPerplexityTokenValidated) var isPerplexityTokenValidated
    @Default(.streamResponse) var streamResponse

    private let tokenManager = TokenValidationManager.shared

    var provider: AIModel.ModelProvider

    var state: TokenValidationState.ValidationState {
        let state = tokenManager.tokenValidation.state(for: provider)
        if state != localState {
            DispatchQueue.main.async {
                localState = state
                updateUse()
            }
        }
        return state
    }

    var models: [AIModel] {
        availableRemoteModels.filter { $0.provider == provider }
    }
    
    var streamResponseBinding: Binding<Bool> {
        switch provider {
        case .openAI:
            return $streamResponse.openAI
        case .anthropic:
            return $streamResponse.anthropic
        case .xAI:
            return $streamResponse.xAI
        case .googleAI:
            return $streamResponse.googleAI
        case .deepSeek:
            return $streamResponse.deepSeek
        case .perplexity:
            return $streamResponse.perplexity
        case .custom:
            return .constant(false)
        }
    }

    // MARK: - Body

    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            titleView
            textField
            errorView
            caption
            modelsView
            advancedSettings
        }
        .onAppear {
            fetchKey()
            checkValidated()
            checkUse()
        }
        .onChange(of: use) {
            save(use: use)
            save(validated: validated)
            // If we've turned off everything go into local mode.
            if appState.listedModels.isEmpty {
                mode = .local
            } else {
                // If it's our first time adding models, set the remoteModel
                if remoteModel == nil {
                    remoteModel = appState.listedModels.first
                }
            }
        }
    }

    // MARK: - Subviews

    var titleView: some View {
        ModelTitle(title: provider.title, isOn: $use)
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
                    tokenManager.tokenValidation.setNotValidated(provider: provider)
                    TokenValidationManager.setTokenIsValid(false, provider: provider)
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
            .disabled(loading || state.isValidating)
            .foregroundStyle(.white)
            .buttonStyle(.borderedProminent)
            .frame(height: 22)
            .fontWeight(.regular)
        }
        .font(.system(size: 13).weight(.regular))
    }

    @ViewBuilder
    var buttonOverlay: some View {
        if loading {
            ProgressView()
                .controlSize(.small)
        } else {
            switch localState {
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
    var advancedSettings: some View {
        // We only support streaming vs. non-streaming for direct-requests
        if use && validated {
            DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
                StreamingToggle(isOn: streamResponseBinding)
                    .padding(.leading, 8)
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    var modelsView: some View {
        // If they're logged in, we should show these since they can always use them through the free plan.
        if use && (appState.userLoggedIn || validated) {
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
        await tokenManager.validateToken(provider: provider, token: key)
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
        case .perplexity:
            perplexityToken = key.isEmpty ? nil : key
        case .custom:
            break
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
        case .perplexity:
            key = perplexityToken ?? ""
        case .custom:
            break
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
        case .perplexity:
            use = usePerplexity
        case .custom:
            break
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
        case .perplexity:
            validated = isPerplexityTokenValidated
        case .custom:
            break
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
        case .perplexity:
            usePerplexity = use
        case .custom:
            break
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
        case .perplexity:
            isPerplexityTokenValidated = validated
        case .custom:
            break
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
