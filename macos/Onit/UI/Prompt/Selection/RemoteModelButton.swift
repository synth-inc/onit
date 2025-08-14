//
//  RemoteModelButton.swift
//  Onit
//
//  Created by Loyd Kim on 5/7/25.
//

import SwiftUI

struct RemoteModelButton: View {
    @Environment(\.appState) var appState
    
    @ObservedObject private var authManager = AuthManager.shared
    
    private let modelSelectionViewOpen: Binding<Bool>
    private let selectedModel: Binding<SelectedModel?>
    private let remoteModel: AIModel
    private let mode: InferenceMode
    
    init(
        modelSelectionViewOpen: Binding<Bool>,
        selectedModel: Binding<SelectedModel?>,
        remoteModel: AIModel,
        mode: InferenceMode
    ) {
        self.modelSelectionViewOpen = modelSelectionViewOpen
        self.selectedModel = selectedModel
        self.remoteModel = remoteModel
        self.mode = mode
    }
    
    @State private var modelProvidersManager = ModelProvidersManager.shared
    
    @State var planLimitReached: Bool = false
    
    var body: some View {
        TextButton(
            iconSize: 16,
            selected: isSelectedRemoteModel(model: remoteModel),
            icon: determineRemoteModelLogo(provider: remoteModel.provider),
            text: remoteModel.displayName
        ) {
            if planLimitReached {
                Circle().fill(Color.blue300).frame(width: 6, height: 6)
            }
        } action: {
            AnalyticsManager.ModelPicker.modelSelected(local: false, model: remoteModel.displayName)
            selectedModel.wrappedValue = .remote(remoteModel)
            modelSelectionViewOpen.wrappedValue = false
            Task {
                await appState.checkSubscriptionAlerts {}
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
        if mode == .remote,
           let currentModel = selectedModel.wrappedValue,
           case let .remote(selectedModel) = currentModel
        {
            return model.id == selectedModel.id
        } else {
            return false
        }
    }
    
    private func checkPlanLimitReached() async {
        do {
            if authManager.userLoggedIn {
                let client = FetchingClient()
                let chatUsageResponse = try await client.getChatUsage()
                
                if let usage = chatUsageResponse?.usage,
                   let quota = chatUsageResponse?.quota
                {
                    let hitPlanLimit = usage >= quota
                    let providerApiKeyExists = modelProvidersManager.getHasValidRemoteProviderToken(provider: remoteModel.provider)
                    
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
