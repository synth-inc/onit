//
//  RemoteModelButton.swift
//  Onit
//
//  Created by Loyd Kim on 5/7/25.
//

import SwiftUI

struct RemoteModelButton: View {
    @Environment(\.appState) var appState
    
    private let modelSelectionViewOpen: Binding<Bool>
    private let selectedModel: Binding<SelectedModel?>
    private let remoteModel: AIModel
    
    init(
        modelSelectionViewOpen: Binding<Bool>,
        selectedModel: Binding<SelectedModel?>,
        remoteModel: AIModel
    ) {
        self.modelSelectionViewOpen = modelSelectionViewOpen
        self.selectedModel = selectedModel
        self.remoteModel = remoteModel
    }
    
    @State var planLimitReached: Bool = false
    
    var body: some View {
        TextButton(
            icon: determineRemoteModelLogo(provider: remoteModel.provider),
            iconSize: 16,
            text: remoteModel.displayName,
            selected: isSelectedRemoteModel(model: remoteModel),
            action: {
                AnalyticsManager.ModelPicker.modelSelected(local: false, model: remoteModel.displayName)
                selectedModel.wrappedValue = .remote(remoteModel)
                modelSelectionViewOpen.wrappedValue = false
                Task {
                    await appState.checkSubscriptionAlerts {}
                }
            }
        ) {
            if planLimitReached {
                Circle().fill(.blue300).frame(width: 6, height: 6)
            }
        }
        .task {
            await checkPlanLimitReached()
        }
    }
}

// MARK: - Private Functions

extension RemoteModelButton {
    private func determineRemoteModelLogo(provider: AIModel.ModelProvider) -> ImageResource {
        switch provider {
        case .openAI: return .logoOpenai
        case .anthropic: return .logoAnthropic
        case .xAI: return .logoXai
        case .googleAI: return .logoGoogleai
        case .deepSeek: return .logoDeepseek
        case .perplexity: return .logoPerplexity
        default: return .logoProviderUnknown
        }
    }
    
    private func isSelectedRemoteModel(model: AIModel) -> Bool {
        if let currentModel = selectedModel.wrappedValue,
           case let .remote(selectedModel) = currentModel {
            return model.id == selectedModel.id
        } else {
            return false
        }
    }
    
    private func checkApiKeyExistsForProvider() -> Bool {
        switch remoteModel.provider {
        case .openAI:
            return appState.isOpenAITokenValidated
        case .anthropic:
            return appState.isAnthropicTokenValidated
        case .xAI:
            return appState.isXAITokenValidated
        case .googleAI:
            return appState.isGoogleAITokenValidated
        case .deepSeek:
            return appState.isDeepSeekTokenValidated
        case .perplexity:
            return appState.isPerplexityTokenValidated
        case .custom:
            return true
        }
    }
    
    private func checkPlanLimitReached() async {
        do {
            let userLoggedIn = appState.account != nil
            
            if userLoggedIn {
                let client = FetchingClient()
                let chatUsageResponse = try await client.getChatUsage()
                
                if let usage = chatUsageResponse?.usage,
                   let quota = chatUsageResponse?.quota
                {
                    let hitPlanLimit = usage >= quota
                    let providerApiKeyExists = checkApiKeyExistsForProvider()
                    
                    if hitPlanLimit && !providerApiKeyExists {
                        planLimitReached = true
                    }
                }
            }
        } catch {
            planLimitReached = false
        }
    }
}
