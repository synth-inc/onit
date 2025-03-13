//
//  AddModelView.swift
//  Onit
//
//  Created by OpenHands on 3/13/25.
//

import SwiftUI
import Defaults

struct AddModelView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.model) var model
    
    @State private var modelName: String = ""
    @State private var displayName: String = ""
    @State private var supportsSystemPrompts: Bool = true
    @State private var supportsVision: Bool = false
    @State private var errorMessage: String? = nil
    
    var provider: AIModel.ModelProvider
    var onModelAdded: ((AIModel) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add a new model")
                .font(.headline)
                .padding(.bottom, 8)
            
            TextField("Model Name", text: $modelName)
                .textFieldStyle(.roundedBorder)
                .frame(height: 22)
                .font(.system(size: 13, weight: .regular))
            
            TextField("Display Name", text: $displayName)
                .textFieldStyle(.roundedBorder)
                .frame(height: 22)
                .font(.system(size: 13, weight: .regular))
            
            Toggle("Supports System Prompts", isOn: $supportsSystemPrompts)
                .font(.system(size: 13, weight: .regular))
                .toggleStyle(.checkbox)
            
            Toggle("Supports Vision", isOn: $supportsVision)
                .font(.system(size: 13, weight: .regular))
                .toggleStyle(.checkbox)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 12))
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Add") {
                    addModel()
                }
                .buttonStyle(.borderedProminent)
                .disabled(modelName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
    
    private func addModel() {
        guard !modelName.isEmpty else {
            errorMessage = "Model name cannot be empty"
            return
        }
        
        // Create a new AIModel
        let newModel = AIModel(
            id: modelName,
            displayName: displayName.isEmpty ? modelName : displayName,
            provider: provider,
            defaultOn: true,
            supportsVision: supportsVision,
            supportsSystemPrompts: supportsSystemPrompts,
            isNew: false,
            isDeprecated: false
        )
        
        // Validate the model by sending a test message
        Task {
            do {
                let isValid = try await model.validateModel(newModel)
                if isValid {
                    // Add the model to the available models
                    DispatchQueue.main.async {
                        var models = Defaults[.availableRemoteModels]
                        models.append(newModel)
                        Defaults[.availableRemoteModels] = models
                        
                        // Enable the model
                        var visibleIds = Defaults[.visibleModelIds]
                        visibleIds.insert(newModel.uniqueId)
                        Defaults[.visibleModelIds] = visibleIds
                        
                        // Call the completion handler
                        onModelAdded?(newModel)
                        
                        // Dismiss the view
                        dismiss()
                    }
                } else {
                    errorMessage = "Failed to validate model. Please check the model name and try again."
                }
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    AddModelView(provider: .anthropic)
}