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

    @State private var loading = false

    var error: String?
    var provider: AIModel.ModelProvider

    var state: TokenValidationState.ValidationState {
        model.tokenValidation.state(for: provider)
    }

    var models: [AIModel] {
        AIModel.allCases.filter { $0.provider == provider }
    }

    var validated: Bool {
        switch provider {
        case .openAI:
            model.isOpenAITokenValidated
        case .anthropic:
            model.isAnthropicTokenValidated
        case .xAI:
            model.isXAITokenValidated
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            titleView
            textField
            errorView
            caption
            modelsView
        }
        .onChange(of: key) {
            save(key: key)
        }
    }

    var titleView: some View {
        HStack {
            Text(provider.title)
                .font(.system(size: 13))
            Spacer()
            Toggle("", isOn: $use)
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(!validated)
        }
    }

    var textField: some View {
        HStack(spacing: 7) {
            TextField("Enter your \(provider.title) API key", text: $key)
                .frame(height: 22)

            Button {
                Task {
                    loading = true
                    await validate()
                    loading = false
                }
            } label: {
                buttonOverlay
            }
            .disabled(state.isValidating || key.isEmpty)
            .foregroundStyle(.FG)
            .buttonStyle(.borderedProminent)
            .frame(height: 22)
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
            Text("Verified ✔")
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

    var caption: some View {
        (
            Text("""
                Add [your \(provider.title) key](\(provider.url)) 
                """)
            +
            Text("""
                to use Onit with \(provider.title) \
                models like \(provider.sample).
                """
            )
        )
        .foregroundStyle(.BG.opacity(0.65))
        .fontWeight(.regular)
        .font(.system(size: 12))
    }

    @ViewBuilder
    var modelsView: some View {
        if use && validated {
            List(models) { model in
                ModelToggle(aiModel: model)
            }
        }
    }

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
}
