//
//  DeleteModelsView.swift
//  Onit
//
//  Created by Loyd Kim on 3/14/25.
//

import SwiftUI
import Defaults

struct DeleteModelsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.model) var model
    
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.visibleModelIds) var visibleModelIds
    
    // Add these properties after other @Default properties
    @Default(.openAIToken) var openAIToken
    @Default(.anthropicToken) var anthropicToken
    @Default(.xAIToken) var xAIToken
    @Default(.googleAIToken) var googleAIToken
    @Default(.deepSeekToken) var deepSeekToken
    @Default(.perplexityToken) var perplexityToken

    // Track selected models for deletion
    @State private var selectedModels = Set<String>()
    @State private var showDeleteConfirmation = false
    
    // Group models by provider
    var modelsByProvider: [(AIModel.ModelProvider, [AIModel])] {
        let filteredModels = availableRemoteModels.filter { model in
            // Only include models whose providers have valid tokens
            switch model.provider {
            case .openAI:
                return openAIToken != nil
            case .anthropic:
                return anthropicToken != nil
            case .xAI:
                return xAIToken != nil
            case .googleAI:
                return googleAIToken != nil
            case .deepSeek:
                return deepSeekToken != nil
            case .perplexity:
                return perplexityToken != nil
            case .custom:
                return false // Not including custom provider models.
            }
        }
        
        let groupedByProvider = Dictionary(grouping: filteredModels) { $0.provider }
        
        
        let providerOrder: [AIModel.ModelProvider] = [
            .openAI,
            .anthropic,
            .xAI,
            .googleAI,
            .deepSeek,
            .perplexity
        ]
        
        // Sorting providers based on the same order found in the Settings -> Models tab.
        return providerOrder.compactMap { provider in
            if let models = groupedByProvider[provider] {
                return (provider, models)
            }
            return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("Delete Models")
                    .font(.system(size:16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                
                // Divider
                Rectangle()
                    .frame(height:1)
                    .foregroundColor(.gray.opacity(0.2))
            }
            .frame(alignment: .center)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(modelsByProvider, id: \.0) { provider, models in
                        if !models.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(provider.title)
                                    .font(.system(size: 14, weight: .bold))
                                
                                ForEach(models) { model in
                                    HStack (spacing: 0) {
                                        Toggle("", isOn: .init(
                                            get: { selectedModels.contains(model.uniqueId) },
                                            set: { isSelected in
                                                if isSelected {
                                                    selectedModels.insert(model.uniqueId)
                                                } else {
                                                    selectedModels.remove(model.uniqueId)
                                                }
                                            }
                                        ))
                                        .toggleStyle(.checkbox)
                                        
                                        Text(model.displayName)
                                            .font(.system(size: 13))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }

            VStack(spacing: 0) {
                // Divider
                Rectangle()
                    .frame(height:1)
                    .foregroundColor(.gray.opacity(0.2))
                
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.secondary)
                    .controlSize(.small)
                    
                    Button("Delete") {
                        showDeleteConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(selectedModels.isEmpty)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
        }
        .frame(width: 330, height: 400)
        .confirmationDialog(
            selectedModels.count > 1 ? "Are you sure you want to delete the selected models?" : "Are you sure you want to delete the selected model?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                // Remove the selected models
                availableRemoteModels.removeAll { model in
                    selectedModels.contains(model.uniqueId)
                }
                
                // Clear selected models from visibleModelIds
                visibleModelIds.subtract(selectedModels)
                
                // Update UI
                model.shrinkContent()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
