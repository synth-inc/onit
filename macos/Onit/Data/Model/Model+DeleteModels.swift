//
//  Model+DeleteModels.swift
//  Onit
//
//  Created by Loyd Kim on 4/9/25.
//

import Defaults

extension OnitModel {
    var modelsByProvider: [(AIModel.ModelProvider, [AIModel])] {
        let filteredModels = Defaults[.availableRemoteModels].filter { model in
            switch model.provider {
            case .openAI:
                return Defaults[.openAIToken] != nil
            case .anthropic:
                return Defaults[.anthropicToken] != nil
            case .xAI:
                return Defaults[.xAIToken] != nil
            case .googleAI:
                return Defaults[.googleAIToken] != nil
            case .deepSeek:
                return Defaults[.deepSeekToken] != nil
            case .perplexity:
                return Defaults[.perplexityToken] != nil
            case .custom: // Not including custom provider models.
                return false
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
        
        return providerOrder.compactMap { provider in
            if let models = groupedByProvider[provider] {
                return (provider, models)
            }
            return nil
        }
    }
    
    func deleteSelectedModels(
        dismiss: @escaping () -> Void
    ) {
        let determineShouldRemoveModel: (AIModel) -> Bool = { model in
            self.modelIdsSelectedForDeletion.contains(model.uniqueId)
        }
        
        Defaults[.availableRemoteModels]
            .filter(determineShouldRemoveModel)
            .forEach { model in
            if !Defaults[.userDeletedRemoteModels].contains(model) {
                Defaults[.userDeletedRemoteModels].append(model)
            }
        }
        
        Defaults[.availableRemoteModels].removeAll(where: determineShouldRemoveModel)
        Defaults[.userAddedCustomRemoteModels].removeAll(where: determineShouldRemoveModel)
        Defaults[.visibleModelIds].subtract(self.modelIdsSelectedForDeletion)
        
        // If the currently-selected model was a member of the models that were just deleted,
        // set the first model in the list of available models as the new currently-selected model.
        if let currentRemoteModel = Defaults[.remoteModel] {
            if !Defaults[.availableRemoteModels].contains(where: {
                $0.uniqueId == currentRemoteModel.uniqueId
            }) {
                if !modelsByProvider.isEmpty {
                    let firstProvider = modelsByProvider[0].1
                    if !firstProvider.isEmpty { Defaults[.remoteModel] = firstProvider[0] }
                    else { Defaults[.remoteModel] = nil }
                } else {
                    Defaults[.remoteModel] = nil
                }
            }
        } else {
            if !modelsByProvider.isEmpty {
                let firstProvider = modelsByProvider[0].1
                
                if !firstProvider.isEmpty {
                    Defaults[.remoteModel] = firstProvider[0]
                }
            }
        }
        
        self.modelIdsSelectedForDeletion.removeAll()
        shrinkContent()
        dismiss()
    }
}
