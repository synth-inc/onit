//
//  ModelSelectionView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import Defaults
import SwiftUI

struct ModelSelectionView: View {
    @Environment(\.model) var model
    @Environment(\.openSettings) var openSettings
    @Environment(\.remoteModels) var remoteModels
    
    @Default(.mode) var mode
    @Default(.localModel) var localModel
    @Default(.remoteModel) var remoteModel
    @Default(.useOpenAI) var useOpenAI
    @Default(.useAnthropic) var useAnthropic
    @Default(.useXAI) var useXAI
    @Default(.useGoogleAI) var useGoogleAI
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.availableLocalModels) var availableLocalModels
    
    @State var searchQuery: String = ""
    
    var filteredRemoteModels: [AIModel] {
        if searchQuery.isEmpty {
            return remoteModels.listedModels
        } else {
            return remoteModels.listedModels.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
    
    var filteredLocalModels: [String] {
        if searchQuery.isEmpty {
            return availableLocalModels
        } else {
            return availableLocalModels.filter {
                $0.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    var selectedModel: Binding<SelectedModel?> {
        .init {
            if mode == .local, let localModelName = localModel {
                return .local(localModelName)
            } else if let aiModel = remoteModel {
                return .remote(aiModel)
            } else {
                return nil
            }
        } set: { newValue in
            guard let newValue else { return }
            switch newValue {
            case .remote(let aiModel):
                remoteModel = aiModel
                mode = .remote
            case .local(let localModelName):
                localModel = localModelName
                mode = .local
            }
        }
    }
    
    var body: some View {
        MenuList(
            header: MenuHeader(title: "Model") {
                IconButton(
                    icon: .settingsCog,
                    iconSize: 18,
                    action: { openModelSettings() },
                    tooltipPrompt: "Settings"
                )
            },
            search: MenuList.Search(
                query: $searchQuery,
                placeholder: "Search models..."
            )
        ) {
            remote
            local
        }
    }

    var remote: some View {
        let noRemoteModels = !remoteModels.remoteNeedsSetup && availableRemoteModels.isEmpty
        
        return MenuSection(
            titleIcon: remoteModels.remoteNeedsSetup || noRemoteModels ? .warningSettings : nil,
            titleIconColor: .orange,
            title: "Remote",
            maxHeight: 178
        ) {
            if remoteModels.listedModels.isEmpty {
                Button("Setup remote models") {
                    model.settingsTab = .models
                    openSettings()
                }
                .buttonStyle(SetUpButtonStyle(showArrow: true))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 10)

            } else {
                remoteModelsView
            }
        }
    }
    
    var remoteModelsView: some View {
        ForEach(filteredRemoteModels) { remoteModel in
            TextButton(
                icon: determineRemoteModelLogo(provider: remoteModel.provider),
                iconSize: 16,
                text: remoteModel.displayName,
                action: { selectedModel.wrappedValue = .remote(remoteModel) }
            )
        }
    }

    var local: some View {
        MenuSection(
            titleIcon: availableLocalModels.isEmpty ? .warningSettings : nil,
            titleIconColor: .orange,
            title: "Local",
            titleChild: add,
            maxHeight: 186
        ) {
            if availableLocalModels.isEmpty {
                Button("Setup local models") {
                    model.settingsTab = .models
                    openSettings()
                }
                .buttonStyle(SetUpButtonStyle(showArrow: true))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 10)

            } else {
                localModelsView
            }
        }
    }

    var localModelsView: some View {
        ForEach(filteredLocalModels, id: \.self) { localModelName in
            TextButton(
                icon: localModelName.lowercased().contains("llama") ? .logoOllama : .logoProviderUnknown,
                iconSize: 16,
                text: localModelName,
                action: { selectedModel.wrappedValue = .local(localModelName) }
            )
        }
    }

    var add: some View {
        HStack(spacing: 4) {
            Text("Add").appFont(.medium13)
            Image(.plus)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(.gray400)
        .cornerRadius(5)
        .opacity(0.3)
        .padding(.bottom, 8)
    }
    
    var custom: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Custom models")
                    .appFont(.medium13)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                if remoteModels.remoteNeedsSetup
                    || (!remoteModels.remoteNeedsSetup && availableRemoteModels.isEmpty)
                {
                    Image(.warningSettings)
                }
            }
            .padding(.horizontal, 12)

            if remoteModels.listedModels.isEmpty {
                Button("Setup remote models") {
                    model.settingsTab = .models
                    openSettings()
                }
                .buttonStyle(SetUpButtonStyle(showArrow: true))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 10)

            } else {
                remoteModelsView
            }
        }
    }
}

// MARK: - Private Functions

extension ModelSelectionView {
    private func openModelSettings() {
        NSApp.activate()
        
        if NSApp.isActive {
            model.setSettingsTab(tab: .models)
            openSettings()
            OverlayManager.shared.dismissOverlay()
        }
    }
    
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
}

// MARK: - Preview

#Preview {
    ModelSelectionView()
}
