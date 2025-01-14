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

    var error: String?
    var provider: AIModel.ModelProvider

    var state: TokenValidationState.ValidationState {
        model.tokenValidation.state(for: provider)
    }

    var models: [AIModel] {
        AIModel.allCases.filter { $0.provider == provider }
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
        .onChange(of: key) {
            save(key: key)
        }
        .onChange(of: state) {
            updateUse()
        }
        .onChange(of: use) {
            save(use: use)
        }
    }

    // MARK: - Subviews

    var titleView: some View {
        ModelTitle(title: provider.title, isOn: $use)
            .disabled(!validated)
    }

    var textField: some View {
        HStack(spacing: 7) {
            TextField("Enter your \(provider.title) API key", text: $key)
                .textFieldStyle(.roundedBorder)
                .frame(height: 22)
                .font(.system(size: 13, weight: .regular))

            Button {
                Task {
                    loading = true
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
            .disabled(state.isValidating || key.isEmpty || validated || state.isValid)
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
        case .notValidated:
            Text("Verify →")
        case .validating:
            ProgressView()
                .controlSize(.small)
        case .valid:
            Text("Verified")
        case .invalid:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    var errorView: some View {
        if let error {
            HStack(spacing: 8) {
                Image(.warning)
                Text(error)
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
        }
    }

    func updateUse() {
        if state == .valid {
            use = true
            validated = true
        }
    }
}
