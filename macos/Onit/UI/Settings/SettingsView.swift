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
    @State private var showOpenAIKey: Bool = false
    @State private var showAnthropicKey: Bool = false
    
    var body: some View {
        Form {
            Section("OpenAI") {
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
                }
                .onChange(of: openAIKey) { _, newValue in
                    Token.openAIToken = newValue.isEmpty ? nil : newValue
                }
                
                Text("Get your API key from [OpenAI](https://platform.openai.com/api-keys)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Anthropic") {
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
                }
                .onChange(of: anthropicKey) { _, newValue in
                    Token.anthropicToken = newValue.isEmpty ? nil : newValue
                }
                
                Text("Get your API key from [Anthropic](https://console.anthropic.com/settings/keys)")
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