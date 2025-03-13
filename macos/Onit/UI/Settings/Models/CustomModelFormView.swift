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
    
    let provider: AIModel.ModelProvider
    
    @State private var modelName = ""
    @State private var displayName = ""
    @State private var supportsSystemPrompts = true
    @State private var supportsVision = false
    
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
                    .textFieldStyle(.plain)
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
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.secondary)
                .controlSize(.small)
                .padding(.vertical, 4)
                
                Button("Verify & Add") {
                    addModel()
                    isSubmitted = true
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .padding(.vertical, 4)
                .disabled(modelName.isEmpty)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 8)
        }
        .padding(20)
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
