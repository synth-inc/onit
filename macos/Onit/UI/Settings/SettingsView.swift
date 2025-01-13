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
    @State private var openAIKey: String = ""
    @State private var anthropicKey: String = ""
    @State private var xAIKey: String = ""
    @State private var showOpenAIKey: Bool = false
    @State private var showAnthropicKey: Bool = false
    @State private var showXAIKey: Bool = false
    
    var body: some View {
        ScrollView { // Make the ModelsTab scrollable
            Form {
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
                                        .foregroundStyle(.green)
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
                        model.openAIToken = newValue.isEmpty ? nil : newValue
                    }
                    
                    Text("Get your API key from [OpenAI](https://platform.openai.com/api-keys)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if model.isOpenAITokenValidated {
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
                }
                
                Section("Anthropic Models") {
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
                                    await model.validateToken(provider: AIModel.ModelProvider.anthropic, token: anthropicKey)
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
                                        .foregroundStyle(.green)
                                case .invalid:
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                            .disabled(anthropicKey.isEmpty || model.tokenValidation.state(for: AIModel.ModelProvider.anthropic).isValidating)
                        }
                        if case .invalid(let error) = model.tokenValidation.state(for: .openAI) {
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .onChange(of: anthropicKey) { _, newValue in
                        model.anthropicToken = newValue.isEmpty ? nil : newValue
                    }
                        
                    Text("Get your API key from [Anthropic](https://console.anthropic.com/settings/keys)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                    if model.isAnthropicTokenValidated {
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
                
                Section("xAI") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ZStack(alignment: .trailing) {
                                if showXAIKey {
                                    TextField("xAI API Key", text: $xAIKey)
                                } else {
                                    SecureField("xAI API Key", text: $xAIKey)
                                }
                                
                                Button(action: { showXAIKey.toggle() }) {
                                    Image(systemName: showXAIKey ? "eye.slash" : "eye")
                                }
                                .buttonStyle(.borderless)
                                .padding(.trailing, 8)
                            }
                            
                            Button(action: {
                                guard !xAIKey.isEmpty else { return }
                                Task {
                                    await model.validateToken(provider: AIModel.ModelProvider.xAI, token: xAIKey)
                                }
                            }) {
                                switch model.tokenValidation.state(for: AIModel.ModelProvider.xAI) {
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
                            .disabled(xAIKey.isEmpty || model.tokenValidation.state(for: AIModel.ModelProvider.xAI).isValidating)
                        }
                        if case .invalid(let error) = model.tokenValidation.state(for: .xAI) {
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .onChange(of: xAIKey) { _, newValue in
                        model.xAIToken = newValue.isEmpty ? nil : newValue
                    }
                        
                    Text("Get your API key from [xAI](https://console.x.ai/)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if model.isXAITokenValidated {
                        ForEach(AIModel.allCases.filter { $0.provider == .xAI }) { aiModel in
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
            }
            .padding(.vertical, 20)
            .onAppear {
                openAIKey = model.openAIToken ?? ""
                anthropicKey = model.anthropicToken ?? ""
                xAIKey = model.xAIToken ?? ""
            }
        }
    }
}

#Preview {
    SettingsView()
}
