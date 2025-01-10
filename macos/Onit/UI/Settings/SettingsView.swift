import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @Environment(\.model) var model
    
    var body: some View {
        TabView {
            ShortcutsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
            
            ModelsTab()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }
            
            APIKeysTab()
                .tabItem {
                    Label("API Keys", systemImage: "key")
                }
        }
        .frame(minWidth: 500, minHeight: 300)
    }
}

private struct ShortcutsTab: View {
    @Environment(\.model) var model
    
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Launch Onit", name: .launch) { _ in
                    Accessibility.resetPrompt(with: StaticPromptView().environment(model))
                }
                .padding()
                
                KeyboardShortcuts.Recorder("Launch Onit - Incognito", name: .launchIncognito) { _ in
                    Accessibility.resetPrompt(with: StaticPromptView().environment(model))
                }
                .padding()
            }
        }
        .padding()
    }
}

private struct ModelsTab: View {
    @Environment(\.model) var model
    
    var body: some View {
        Form {
            Section("OpenAI Models") {
                ForEach(AIModel.allCases.filter { $0.provider == .openAI }) { aiModel in
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
            
            Section("Anthropic Models") {
                ForEach(AIModel.allCases.filter { $0.provider == .anthropic }) { aiModel in
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
        .padding(.vertical, 20)
    }
}

private struct APIKeysTab: View {
    @State private var openAIKey: String = ""
    @State private var anthropicKey: String = ""
    @State private var xAIKey: String = ""
    @State private var showOpenAIKey: Bool = false
    @State private var showAnthropicKey: Bool = false
    @State private var showXAIKey: Bool = false
    
    var body: some View {
        Form {
            Section("OpenAI") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if showOpenAIKey {
                            TextField("OpenAI API Key", text: $openAIKey)
                        } else {
                            SecureField("OpenAI API Key", text: $openAIKey)
                        }
                        
                        Button(action: { showOpenAIKey.toggle() }) {
                            Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                        
                        Button(action: {
                            guard !openAIKey.isEmpty else { return }
                            Task {
                                await model.validateToken(provider: .openAI, token: openAIKey)
                            }
                        }) {
                            switch model.tokenValidation.state(for: .openAI) {
                            case .notValidated:
                                Text("Validate")
                            case .validating:
                                ProgressView()
                                    .controlSize(.small)
                            case .valid:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            case .invalid:
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .disabled(openAIKey.isEmpty || model.tokenValidation.state(for: .openAI).isValidating)
                    }
                    
                    if case .invalid(let error) = model.tokenValidation.state(for: .openAI) {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .onChange(of: openAIKey) { _, newValue in
                    Token.openAIToken = newValue.isEmpty ? nil : newValue
                }
                
                Text("Get your API key from [OpenAI](https://platform.openai.com/api-keys)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Anthropic") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if showAnthropicKey {
                            TextField("Anthropic API Key", text: $anthropicKey)
                        } else {
                            SecureField("Anthropic API Key", text: $anthropicKey)
                        }
                        
                        Button(action: { showAnthropicKey.toggle() }) {
                            Image(systemName: showAnthropicKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                        
                        Button(action: {
                            guard !anthropicKey.isEmpty else { return }
                            Task {
                                await model.validateToken(provider: .anthropic, token: anthropicKey)
                            }
                        }) {
                            switch model.tokenValidation.state(for: .anthropic) {
                            case .notValidated:
                                Text("Validate")
                            case .validating:
                                ProgressView()
                                    .controlSize(.small)
                            case .valid:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            case .invalid:
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .disabled(anthropicKey.isEmpty || model.tokenValidation.state(for: .anthropic).isValidating)
                    }
                    
                    if case .invalid(let error) = model.tokenValidation.state(for: .anthropic) {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .onChange(of: anthropicKey) { _, newValue in
                    Token.anthropicToken = newValue.isEmpty ? nil : newValue
                }
                
                Text("Get your API key from [Anthropic](https://console.anthropic.com/settings/keys)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("xAI") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if showXAIKey {
                            TextField("xAI API Key", text: $xAIKey)
                        } else {
                            SecureField("xAI API Key", text: $xAIKey)
                        }
                        
                        Button(action: { showXAIKey.toggle() }) {
                            Image(systemName: showXAIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                        
                        Button(action: {
                            guard !xAIKey.isEmpty else { return }
                            Task {
                                await model.validateToken(provider: .xAI, token: xAIKey)
                            }
                        }) {
                            switch model.tokenValidation.state(for: .xAI) {
                            case .notValidated:
                                Text("Validate")
                            case .validating:
                                ProgressView()
                                    .controlSize(.small)
                            case .valid:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            case .invalid:
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .disabled(xAIKey.isEmpty || model.tokenValidation.state(for: .xAI).isValidating)
                    }
                    
                    if case .invalid(let error) = model.tokenValidation.state(for: .xAI) {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .onChange(of: xAIKey) { _, newValue in
                    Token.xAIToken = newValue.isEmpty ? nil : newValue
                }
                
                Text("Get your API key from [xAI](https://x.ai/api)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}