//
//  Model+AddCustomModels.swift
//  Onit
//
//  Created by Loyd Kim on 4/9/25.
//

import Defaults
import Foundation

extension OnitModel {
    func validateAndAddModel(
        modelName: String,
        displayName: String,
        supportsVision: Bool,
        supportsSystemPrompts: Bool,
        provider: AIModel.ModelProvider,
        token: String?,
        dismiss: @escaping () -> Void
    ) async {
        verifyingCustomModel = true
        defer { verifyingCustomModel = false }
        verifyingCustomModelErrorMessage = nil
        
        // First check if the model has already been added to Onit.
        let newModel = AIModel(
            id: modelName,
            displayName: displayName.isEmpty ? modelName : displayName,
            provider: provider,
            defaultOn: false,
            supportsVision: supportsVision,
            supportsSystemPrompts: supportsSystemPrompts
        )
        
        if Defaults[.availableRemoteModels].contains(where: {
            $0.uniqueId == newModel.uniqueId
        }) {
            verifyingCustomModel = false
            verifyingCustomModelErrorMessage = "Model already added."
            return
        }
        
        // If we get here, the model has yet to be added, so it's safe to proceed with model validation.
        do {
            let modelValidationEndpoint = ModelValidationEndpoint(
                provider: provider,
                model: modelName,
                token: token
            )
            
            let client = FetchingClient()
            
            #if DEBUG
                print("Validating model: \(modelName) for provider: \(provider)")
            #endif

            _ = try await client.execute(modelValidationEndpoint)
            
            // If we get here, validation succeeded.
            // The model will be added to Onit and will automatically be selected for use.
            addNewModel(newModel: newModel)
            
            isCustomModelSubmitted = true
            dismiss()
        } catch let error {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    verifyingCustomModelErrorMessage = "No internet connection."
                case .timedOut:
                    verifyingCustomModelErrorMessage = "Request timed out. Please try again."
                case .cannotConnectToHost:
                    verifyingCustomModelErrorMessage = "Network error. Please try again."
                default:
                    verifyingCustomModelErrorMessage = "Model name invalid."
                }
            } else {
                verifyingCustomModelErrorMessage = "Model name invalid."
            }
            
            #if DEBUG
                print("\n\n\n")
                print("Error Message: \(verifyingCustomModelErrorMessage ?? "")")
                print("Custom model validation error details: \(error)")
                print("\n\n\n")
            #endif
        }
        
        verifyingCustomModel = false
    }
    
    private func addNewModel(newModel: AIModel) {
        if !Defaults[.availableRemoteModels].contains(newModel) {
            Defaults[.availableRemoteModels].append(newModel)
        }
        
        if !Defaults[.userAddedCustomRemoteModels].contains(newModel) {
            Defaults[.userAddedCustomRemoteModels].append(newModel)
        }
        
        Defaults[.visibleModelIds].insert(newModel.uniqueId)
    }
}
