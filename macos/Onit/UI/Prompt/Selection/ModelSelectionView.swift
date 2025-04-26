//
//  ModelSelectionView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import Defaults
import SwiftUI

struct ModelSelectionView: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings
    
    @Default(.mode) var mode
    @Default(.localModel) var localModel
    @Default(.remoteModel) var remoteModel
    @Default(.useOpenAI) var useOpenAI
    @Default(.useAnthropic) var useAnthropic
    @Default(.useXAI) var useXAI
    @Default(.useGoogleAI) var useGoogleAI
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.availableLocalModels) var availableLocalModels
    
    private var open: Binding<Bool>
    init(open: Binding<Bool>) { self.open = open }
    
    @State var searchQuery: String = ""
    
    private var filteredRemoteModels: [AIModel] {
        if searchQuery.isEmpty {
            return appState.listedModels
        } else {
            return appState.listedModels.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
    
    private var filteredLocalModels: [String] {
        if searchQuery.isEmpty {
            return availableLocalModels
        } else {
            return availableLocalModels.filter {
                $0.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    private var selectedModel: Binding<SelectedModel?> {
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
        let noRemoteModels = !appState.remoteNeedsSetup && availableRemoteModels.isEmpty
        
        return MenuSection(
            titleIcon: appState.remoteNeedsSetup || noRemoteModels ? .warningSettings : nil,
            titleIconColor: .orange,
            title: "Remote",
            showTopBorder: true,
            contentRightPadding: 0,
            contentBottomPadding: 0,
            contentLeftPadding: 0
        ) {
            if appState.listedModels.isEmpty {
                Button("Setup remote models") {
                    appState.settingsTab = .models
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
        ScrollView {
            VStack(spacing: 0) {
                ForEach(filteredRemoteModels) { remoteModel in
                    TextButton(
                        icon: determineRemoteModelLogo(provider: remoteModel.provider),
                        iconSize: 16,
                        text: remoteModel.displayName,
                        selected: isSelectedRemoteModel(model: remoteModel),
                        action: {
                            selectedModel.wrappedValue = .remote(remoteModel)
                            open.wrappedValue = false
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(
            maxHeight:
                setModelListHeight(
                    listCount: CGFloat(filteredRemoteModels.count)
                )
        )
    }

    var local: some View {
        MenuSection(
            titleIcon: availableLocalModels.isEmpty ? .warningSettings : nil,
            titleIconColor: .orange,
            title: "Local",
            titleChild: add,
            showTopBorder: true,
            contentRightPadding: 0,
            contentBottomPadding: 0,
            contentLeftPadding: 0
        ) {
            if availableLocalModels.isEmpty {
                Button("Setup local models") {
                    appState.settingsTab = .models
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
        ScrollView {
            VStack(spacing: 0) {
                ForEach(filteredLocalModels, id: \.self) { localModelName in
                    TextButton(
                        icon: localModelName.lowercased().contains("llama") ? .logoOllama : .logoProviderUnknown,
                        iconSize: 16,
                        text: localModelName,
                        selected: isSelectedLocalModel(modelName: localModelName),
                        action: {
                            selectedModel.wrappedValue = .local(localModelName)
                            open.wrappedValue = false
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(
            maxHeight:
                setModelListHeight(
                    listCount: CGFloat(filteredLocalModels.count)
                )
        )
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
                if appState.remoteNeedsSetup
                    || (!appState.remoteNeedsSetup && availableRemoteModels.isEmpty)
                {
                    Image(.warningSettings)
                }
            }
            .padding(.horizontal, 12)

            if appState.listedModels.isEmpty {
                Button("Setup remote models") {
                    appState.settingsTab = .models
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
    private func setModelListHeight(listCount: CGFloat) -> CGFloat {
        let buttonHeight: CGFloat = 32
        
        let maxShownButtonCount: CGFloat = 6
        let nextButtonPeekHeight: CGFloat = 20
        let listMaxHeight: CGFloat = (maxShownButtonCount * buttonHeight) + nextButtonPeekHeight
        
        let listBottomPaddingBuffer: CGFloat = 8
        let listHeight: CGFloat = listCount * buttonHeight + listBottomPaddingBuffer
        
        if listHeight < listMaxHeight {
            return listHeight
        } else {
            return listMaxHeight
        }
    }
    
    private func openModelSettings() {
        NSApp.activate()
        
        if NSApp.isActive {
            appState.setSettingsTab(tab: .models)
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
    
    private func isSelectedRemoteModel(model: AIModel) -> Bool {
        if let currentModel = selectedModel.wrappedValue,
           case let .remote(selectedModel) = currentModel {
            return model.id == selectedModel.id
        } else {
            return false
        }
    }
    
    private func isSelectedLocalModel(modelName: String) -> Bool {
        if let currentModel = selectedModel.wrappedValue,
           case let .local(selectedName) = currentModel {
            return modelName == selectedName
        } else {
            return false
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var open = true
    ModelSelectionView(open: $open)
}
