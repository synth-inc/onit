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
    
    @State private var use = false
    @State private var key = ""
    @State private var validated = false
    @State private var loading = false
    @State private var showAdvanced: Bool = false
    @State private var showAPIKeyInput: Bool = false
    @State private var localState: TokenValidationState.ValidationState = .notValidated

    private let tokenManager = TokenValidationManager.shared

    var provider: AIModel.ModelProvider
    
    private var isLoggedIn: Bool {
        appState.account != nil
    }

    private var tokenValidationState: TokenValidationState.ValidationState {
        let state = tokenManager.tokenValidation.state(for: provider)
        if state != localState {
            DispatchQueue.main.async {
                localState = state
                updateUse()
            }
        }
        return state
    }

    private var models: [AIModel] {
        availableRemoteModels.filter { $0.provider == provider }
    }
    
    private var streamResponseBinding: Binding<Bool> {
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
            errorView
            modelsView
            advancedSettings
            apiKeyDropdown
            
            PromptDivider()
                .padding(.top, 8)
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

// MARK: - Child Components
    
    private var titleView: some View {
        ModelTitle(
            title: provider.title,
            isOn: $use,
            showToggle: isLoggedIn || validated
        )
    }

    @ViewBuilder
    private var errorView: some View {
        if case .invalid(let error) = tokenValidationState {
            ModelErrorView(errorMessage: error.localizedDescription)
        }
    }
    
    @ViewBuilder
    private var modelsView: some View {
        // If user is logged in, allow them to select models (available through free/paid plans).
        if use && (isLoggedIn || validated) {
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
    
    @ViewBuilder
    private var advancedSettings: some View {
        // We only support streaming vs. non-streaming for direct-requests
        if use && isLoggedIn && validated {
            DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
                StreamingToggle(isOn: streamResponseBinding)
                    .padding(.leading, 8)
                    .padding(.top, 4)
            }
        }
    }
    
    @ViewBuilder
    private var buttonOverlay: some View {
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
    
    private var verifiedButton: some View {
        SimpleButton(
            text: "Verified",
            disabled: true,
            textColor: .black,
            background: .white
        )
    }
    
    private var removeApiKeyButton: some View {
        SimpleButton(text: "Remove") {
            removeApiKey()
        }
    }
    
    private var disableVerifyButton: Bool {
        loading || tokenValidationState.isValidating
    }
    
    private var verifyButton: some View {
        SimpleButton(
            text: loading ? "Verifying" : "Verify →",
            loading: loading,
            disabled: disableVerifyButton,
            background: .blue
        ) {
            Task {
                loading = true
                save(key: key)
                tokenManager.tokenValidation.setNotValidated(provider: provider)
                TokenValidationManager.setTokenIsValid(false, provider: provider)
                await validate()
                setValidated(isValid: true)
                loading = false
            }
        }
    }
    
    private var apiKeyInputField: some View {
        HStack(alignment: .center, spacing: 8) {
            SecureField("Enter your \(provider.title) API key", text: $key)
                .textFieldStyle(.roundedBorder)
                .frame(height: 22)
                .styleText(size: 13, weight: .regular)
            
            if validated {
                verifiedButton
                removeApiKeyButton
            } else {
                verifyButton
            }
        }
        .font(.system(size: 13).weight(.regular))
    }
    
    private var providerLinkText: String {
        "[your \(provider.title) key](\(provider.url))"
    }

    private var apiKeyCaption: some View {
        (Text("You can put in ")
            + Text(.init(providerLinkText))
            + Text(
                """
                 to use \(provider.title) models at cost.
                """
            ))
            .foregroundStyle(.foreground.opacity(0.65))
            .fontWeight(.regular)
            .font(.system(size: 12))
    }
    
    private var apiKeyDropdown: some View {
        DisclosureGroup(
            "\(provider.title) API Key\(validated ? " ✅" : "")",
            isExpanded: $showAPIKeyInput
        ) {
            VStack(alignment: .leading, spacing: 8) {
                apiKeyInputField
                apiKeyCaption
            }
            .padding(.top, 8)
        }
    }

// MARK: - Private Functions

    private func validate() async {
        await tokenManager.validateToken(provider: provider, token: key)
    }

    private func save(key: String) {
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

    private func fetchKey() {
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

    private func checkUse() {
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
    
    private func setValidated(isValid: Bool) {
        switch provider {
        case .openAI:
            isOpenAITokenValidated = isValid
        case .anthropic:
            isAnthropicTokenValidated = isValid
        case .xAI:
            isXAITokenValidated = isValid
        case .googleAI:
            isGoogleAITokenValidated = isValid
        case .deepSeek:
            isDeepSeekTokenValidated = isValid
        case .perplexity:
            isPerplexityTokenValidated = isValid
        case .custom:
            break
        }
        
        validated = isValid
    }

    private func checkValidated() {
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

    private func save(use: Bool) {
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

    private func save(validated: Bool) {
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
    
    private func removeApiKey() {
        switch provider {
        case .openAI:
            openAIToken = nil
            isOpenAITokenValidated = false
        case .anthropic:
            anthropicToken = nil
            isAnthropicTokenValidated = false
        case .xAI:
            xAIToken = nil
            isXAITokenValidated = false
        case .googleAI:
            googleAIToken = nil
            isGoogleAITokenValidated = false
        case .deepSeek:
            deepSeekToken = nil
            isDeepSeekTokenValidated = false
        case .perplexity:
            perplexityToken = nil
            isPerplexityTokenValidated = false
        case .custom:
            break
        }
        
        key = ""
        validated = false
    }

    private func updateUse() {
        if tokenValidationState == .valid {
            use = true
            validated = true
        } else if case .invalid(_) = tokenValidationState {
            use = false
            validated = false
        }
    }
}
