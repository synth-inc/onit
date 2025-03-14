//
//  CustomModelFormView.swift
//  Onit
//
//  Created by Loyd Kim on 3/13/25.
//

import SwiftUI
import Defaults

struct CustomModelFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.model) var model
    
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.visibleModelIds) var visibleModelIds
    
    let provider: AIModel.ModelProvider
    let token: String?
    
    @State private var modelName = ""
    @State private var displayName = ""
    @State private var supportsSystemPrompts = true
    @State private var supportsVision = false
    @State private var isVerifying = false
    @State private var errorMessage: String? = nil
    
    @Binding var isSubmitted: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Model Name")
                    .font(.system(size: 13))
                TextField("", text: $modelName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
                    .placeholder(when: modelName.isEmpty) {
                        Text("gpt-4o-mini-07-18-2024")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .textFieldStyle(.plain)
                    }
                    .onSubmit(submit)
            }
            .frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.system(size: 13))
                TextField("", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
                    .placeholder(when: displayName.isEmpty) {
                        Text("GPT-4o Mini")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .textFieldStyle(.plain)
                    }
                    .onSubmit(submit)
            }
            .frame(maxWidth: .infinity)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Supports System Prompts")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle("", isOn: $supportsSystemPrompts)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                HStack {
                    Text("Supports Vision")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle("", isOn: $supportsVision)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }
            .frame(maxWidth: .infinity)
            
            VStack {
                HStack {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 13))
                    }
                    
                    Spacer(minLength: 16)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.secondary)
                    .controlSize(.small)
                    .padding(.vertical, 4)
                    
                    Button {
                        Task {
                            await validateAndAddModel()
                        }
                    } label: {
                        if isVerifying {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Verify & Add")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.vertical, 4)
                    .disabled(modelName.isEmpty || isVerifying)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 8)
        }
        .padding(.top,20)
        .padding(.horizontal,20)
        .padding(.bottom, 16)
        .frame(width: 330)
    }
    
    private func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    private func validateAndAddModel() async {
        isVerifying = true
        errorMessage = nil
        
        // First check if the model has already been added to Onit.
        let potentialModel = AIModel(
            id: modelName,
            displayName: displayName.isEmpty ? modelName : displayName,
            provider: provider,
            defaultOn: false,
            supportsVision: supportsVision,
            supportsSystemPrompts: supportsSystemPrompts
        )
        
        if availableRemoteModels.contains(where: { $0.uniqueId == potentialModel.uniqueId }) {
            errorMessage = "Model already added."
            isVerifying = false
            return
        }
        
        // If we get here, the model has yet to be added, so it's safe to proceed with model validation.
        do {
            let endpoint = ModelValidationEndpoint(
                model: modelName,
                token: token,
                provider: provider
            )
            
            let client = FetchingClient()
            print("Validating model: \(modelName) for provider: \(provider)")
            
            _ = try await client.execute(endpoint)
            
            // If we get here, validation succeeded.
            // The model will be added to Onit and will automatically be checked.
            addModel()
            isSubmitted = true
            dismiss()
        } catch let error {
            print("\n\n\n")
            print("Unexpected validation error: \(error)")
            if let urlError = error as? URLError {
                print("Network error: \(urlError.localizedDescription)")
            } else {
                print("Invalid model name: \(error.localizedDescription)")
            }
            print("\n\n\n")
            
            errorMessage = "Model name invalid."
        }
        
        isVerifying = false
    }
    
    private func addModel() {
        let newModel = AIModel(
            id: modelName,
            displayName: displayName.isEmpty ? modelName : displayName,
            provider: provider,
            defaultOn: false,
            supportsVision: supportsVision,
            supportsSystemPrompts: supportsSystemPrompts
        )
        
        availableRemoteModels.append(newModel)
        
        visibleModelIds.insert(newModel.uniqueId)
    }
    
    private func submit() {
        if !modelName.isEmpty && !isVerifying {
            Task {
                await validateAndAddModel()
            }
        }
    }
}

// MARK: - AIModel Extension

extension AIModel {
    init(id: String,
         displayName: String,
         provider: ModelProvider,
         defaultOn: Bool,
         supportsVision: Bool,
         supportsSystemPrompts: Bool) {
        self.id = id
        self.displayName = displayName
        self.provider = provider
        self.defaultOn = defaultOn
        self.supportsVision = supportsVision
        self.supportsSystemPrompts = supportsSystemPrompts
        self.isNew = false
        self.isDeprecated = false
        self.customProviderName = nil
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
