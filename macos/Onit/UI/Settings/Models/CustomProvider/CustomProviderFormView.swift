//
//  CustomProviderFormView.swift
//  Onit
//
//  Created by Kévin Naudin on 05/02/2025.
//

import Defaults
import SwiftUI

struct CustomProviderFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Default(.availableCustomProvider) var availableCustomProviders
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.visibleModelIds) var visibleModelIds
    
    @State var name: String = ""
    @State var baseURL: String = ""
    @State var token: String = ""
    
    @Binding var isSubmitted: Bool

    @State private var errorMessage: String?
    
    var body: some View {
        Form {
            
            Text("Add a new provider")
                .font(.headline)
                .padding(.bottom, 12)
            
            VStack(spacing: 16) {
                LabeledTextField(label: "Provider Name", text: $name)
                LabeledTextField(label: "URL", text: $baseURL)
                LabeledTextField(label: "Token", text: $token, secure: true)
            }
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Verify & Save") {
                    errorMessage = nil
                    addProvider()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || baseURL.isEmpty || token.isEmpty)
            }.padding(.top, 8)
            
            if let errorMessage = errorMessage{
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 330)
    }
    
    private func addProvider() {
        Task {
            do {
                
                try await fetchModels()

                DispatchQueue.main.async {
                    isSubmitted = true
                    dismiss()
                }
            } catch {
                errorMessage = "Failed to fetch models: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchModels() async throws {
        guard let url = URL(string: baseURL) else { return }
        
        let endpoint = CustomModelsEndpoint(baseURL: url, token: token)
        let client = FetchingClient()
        let response = try await client.execute(endpoint)
        
        let models = response.data.map { $0.id }
        let provider = CustomProvider(
            name: name,
            baseURL: baseURL,
            token: token,
            models: models
        )
        
        availableCustomProviders.append(provider)
        
        // Initialize model IDs
        let newModels = models.map { modelId in
            AIModel(from: CustomModelInfo(
                id: modelId,
                object: "model",
                created: Int(Date().timeIntervalSince1970),
                owned_by: name
            ), providerName: provider.name)
        }
        
        // Initialize visible model IDs
        visibleModelIds = visibleModelIds.union(Set(newModels.map { $0.id }))
        
        // Add new models to available remote models
        availableRemoteModels.append(contentsOf: newModels)
    }
}

#Preview {
    CustomProviderFormView(isSubmitted: .constant(false))
}
