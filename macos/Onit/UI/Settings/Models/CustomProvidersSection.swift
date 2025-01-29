import SwiftUI
import SwiftData

struct CustomProvidersSection: View {
    @Environment(\.model) var model
    @Environment(\.modelContext) private var modelContext
    @Query private var customProviders: [CustomProvider]
    
    @State private var isAddingProvider = false
    @State private var newProviderName = ""
    @State private var newProviderURL = ""
    @State private var newProviderToken = ""
    @State private var errorMessage: String?
    
    var body: some View {
        RemoteModelSection(title: "Custom Providers") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(customProviders) { provider in
                    CustomProviderRow(provider: provider)
                }
                
                if isAddingProvider {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Provider Name", text: $newProviderName)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Base URL", text: $newProviderURL)
                            .textFieldStyle(.roundedBorder)
                        
                        SecureField("API Token", text: $newProviderToken)
                            .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Button("Add Provider") {
                                addProvider()
                            }
                            .disabled(newProviderName.isEmpty || newProviderURL.isEmpty || newProviderToken.isEmpty)
                            
                            Button("Cancel") {
                                isAddingProvider = false
                                resetForm()
                            }
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                } else {
                    Button("Add Custom Provider") {
                        isAddingProvider = true
                    }
                }
            }
        }
    }
    
    private func addProvider() {
        Task {
            do {
                let provider = CustomProvider(
                    name: newProviderName,
                    baseURL: newProviderURL,
                    token: newProviderToken
                )
                
                try await provider.fetchModels()
                modelContext.insert(provider)
                
                isAddingProvider = false
                resetForm()
            } catch {
                errorMessage = "Failed to fetch models: \(error.localizedDescription)"
            }
        }
    }
    
    private func resetForm() {
        newProviderName = ""
        newProviderURL = ""
        newProviderToken = ""
        errorMessage = nil
    }
}

struct CustomProviderRow: View {
    @Environment(\.model) var model
    @Environment(\.modelContext) private var modelContext
    
    let provider: CustomProvider
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Toggle(isOn: .init(
                    get: { provider.isEnabled },
                    set: { provider.isEnabled = $0 }
                )) {
                    Text(provider.name)
                        .font(.headline)
                }
                
                Spacer()
                
                Button(role: .destructive) {
                    // Remove provider's models from available remote models
                    model.updatePreferences { prefs in
                        prefs.availableRemoteModels.removeAll { model in
                            model.customProvider?.id == provider.id
                        }
                    }
                    modelContext.delete(provider)
                } label: {
                    Image(systemName: "trash")
                }
            }
            
            if provider.isEnabled {
                GroupBox {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(provider.models, id: \.self) { modelId in
                            let aiModel = AIModel(
                                from: CustomModelInfo(
                                    id: modelId,
                                    object: "model",
                                    created: Int(Date().timeIntervalSince1970),
                                    owned_by: provider.name
                                ),
                                provider: provider
                            )
                            ModelToggle(aiModel: aiModel)
                                .frame(height: 36)
                        }
                    }
                    .padding(.vertical, -4)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
    }
}
