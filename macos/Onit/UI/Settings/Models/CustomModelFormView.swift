//
//  CustomModelFormView.swift
//  Onit
//
//  Created by Loyd Kim on 3/13/25.
//

import SwiftUI
import Defaults

struct CustomModelFormView: View {
    @Environment(\.model) var model
    @Environment(\.dismiss) private var dismiss
    
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.userAddedCustomRemoteModels) var userAddedCustomRemoteModels
    @Default(.visibleModelIds) var visibleModelIds
    
    let provider: AIModel.ModelProvider
    let token: String?
    
    @State private var modelName = ""
    @State private var displayName = ""
    @State private var supportsSystemPrompts = true
    @State private var supportsVision = false
    
    var body: some View {
        VStack(spacing: 16) {
            modelNameInput
            displayNameInput
            
            VStack(spacing: 8) {
                supportsSystemPromptsToggleSwitch
                supportsVisionToggleSwitch
            }.frame(maxWidth: .infinity)
            
            VStack {
                HStack {
                    errorMessageText
                    Spacer()
                    cancelButton
                    submitButton
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
}

/// Child Components
extension CustomModelFormView {
    var modelNameInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model Name")
                .font(.system(size: 13))
            TextField("gpt-4o-mini-07-18-2024", text: $modelName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))
                .onSubmit(submit)
        }
        .frame(maxWidth: .infinity)
    }
    
    var displayNameInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display Name")
                .font(.system(size: 13))
            TextField("GPT-4o Mini", text: $displayName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))
                .onSubmit(submit)
        }
        .frame(maxWidth: .infinity)
    }
    
    var supportsSystemPromptsToggleSwitch: some View {
        HStack {
            Text("Supports System Prompts")
                .font(.system(size: 13))
            Spacer()
            Toggle("", isOn: $supportsSystemPrompts)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
    
    var supportsVisionToggleSwitch: some View {
        HStack {
            Text("Supports Vision")
                .font(.system(size: 13))
            Spacer()
            Toggle("", isOn: $supportsVision)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
    
    @ViewBuilder
    var errorMessageText: some View {
        if let errorMessage = model.verifyingCustomModelErrorMessage {
            Text(errorMessage)
                .foregroundColor(.red)
                .font(.system(size: 13))
        }
    }
    
    var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
        .buttonStyle(.borderedProminent)
        .tint(.secondary)
        .controlSize(.small)
        .padding(.vertical, 4)
    }
    
    var submitButton: some View {
        Button {
            Task {
                await model.validateAndAddModel(
                    modelName: modelName,
                    displayName: displayName,
                    supportsVision: supportsVision,
                    supportsSystemPrompts: supportsSystemPrompts,
                    provider: provider,
                    token: token,
                    dismiss: { dismiss() }
                )
            }
        } label: {
            if model.verifyingCustomModel {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text("Verify & Add")
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .padding(.vertical, 4)
        .disabled(modelName.isEmpty || model.verifyingCustomModel)
    }
}

/// Private Functions
extension CustomModelFormView {
    private func submit() {
        if !modelName.isEmpty && !model.verifyingCustomModel {
            Task {
                await model.validateAndAddModel(
                    modelName: modelName,
                    displayName: displayName,
                    supportsVision: supportsVision,
                    supportsSystemPrompts: supportsSystemPrompts,
                    provider: provider,
                    token: token,
                    dismiss: { dismiss() }
                )
            }
        }
    }
}
