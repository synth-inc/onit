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
        .padding()
    }
}

#Preview {
    SettingsView()
}