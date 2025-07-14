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
                    tooltipPrompt: "Settings"
                ) {
                    AnalyticsManager.ModelPicker.settingsPressed()
                    openModelSettings()
                }
            },
            search: MenuList.Search(
                query: $searchQuery,
                placeholder: "Search models..."
            )
        ) {
            signInCTA
            remote
            local
        }
        .onAppear {
            AnalyticsManager.ModelPicker.opened()
        }
    }
    
    private func emptyText(_ text: String) -> some View {
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .styleText(
                size: 13,
                weight: .regular,
                color: .gray100
            )
    }
    
    private func arrowButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(text) {
            action()
        }
        .buttonStyle(SetUpButtonStyle(showArrow: true))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var signInCTA: some View {
        if !appState.userLoggedIn {
            VStack(alignment: .leading, spacing: 8) {
                emptyText("Sign in to gain access to models from OpenAI, Anthropic, and more!")
                
                arrowButton("Sign In") {
                    GeneralTabAccount.openSignInAuth()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    var remote: some View {
        return MenuSection(
            title: "Remote",
            showTopBorder: true,
            maxScrollHeight: !filteredRemoteModels.isEmpty ? setModelListHeight(
                listCount: CGFloat(filteredRemoteModels.count)
            ) : nil,
            contentRightPadding: 0,
            contentBottomPadding: 0,
            contentLeftPadding: 0
        ) {
            if filteredRemoteModels.isEmpty {
                emptyText("No remote models.")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            } else {
                remoteModelsView
            }
        }
    }
    
    var remoteModelsView: some View {
        VStack(spacing: 0) {
            ForEach(filteredRemoteModels) { remoteModel in
                RemoteModelButton(
                    modelSelectionViewOpen: open,
                    selectedModel: selectedModel,
                    remoteModel: remoteModel
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    var local: some View {
        MenuSection(
            title: "Local",
            showTopBorder: true,
            maxScrollHeight: !filteredLocalModels.isEmpty ? setModelListHeight(
                listCount: CGFloat(filteredLocalModels.count)
            ) : nil,
            contentRightPadding: 0,
            contentBottomPadding: 0,
            contentLeftPadding: 0
        ) {
            if availableLocalModels.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    emptyText("No local models.")
                    
                    arrowButton("Setup local models") {
                        AnalyticsManager.ModelPicker.localSetupPressed()
                        appState.settingsTab = .models
                        openSettings()
                    }
                    
                }
                .padding([.horizontal, .bottom], 16)
            } else {
                localModelsView
            }
        }
    }

    var localModelsView: some View {
        VStack(spacing: 0) {
            ForEach(filteredLocalModels, id: \.self) { localModelName in
                TextButton(
                    iconSize: 16,
                    selected: isSelectedLocalModel(modelName: localModelName),
                    icon: localModelName.lowercased().contains("llama") ? .logoOllama : .logoProviderUnknown,
                    text: localModelName,
                    action: {
                        AnalyticsManager.ModelPicker.modelSelected(local: true, model: localModelName)
                        selectedModel.wrappedValue = .local(localModelName)
                        open.wrappedValue = false
                    }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
    
//    var custom: some View {
//        VStack(alignment: .leading, spacing: 2) {
//            HStack {
//                Text("Custom models")
//                    .appFont(.medium13)
//                    .foregroundStyle(.white.opacity(0.6))
//                Spacer()
//                if appState.remoteNeedsSetup
//                    || (!appState.remoteNeedsSetup && availableRemoteModels.isEmpty)
//                {
//                    Image(.warningSettings)
//                }
//            }
//            .padding(.horizontal, 12)
//
//            if appState.listedModels.isEmpty {
//                Button("Setup remote models") {
//                    appState.settingsTab = .models
//                    openSettings()
//                }
//                .buttonStyle(SetUpButtonStyle(showArrow: true))
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.horizontal, 12)
//                .padding(.top, 6)
//                .padding(.bottom, 10)
//
//            } else {
//                remoteModelsView
//            }
//        }
//    }
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
