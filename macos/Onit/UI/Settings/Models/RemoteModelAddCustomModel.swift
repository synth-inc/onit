//
//  RemoteModelAddCustomModel.swift
//  Onit
//
//  Created by Loyd Kim on 7/21/25.
//

import Defaults
import SwiftUI

struct RemoteModelAddCustomModel: View {
    @Environment(\.appState) var appState
    
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.userAddedRemoteModels) var userAddedRemoteModels
    @Default(.userRemovedRemoteModels) var userRemovedRemoteModels
    
    // MARK: - Properties
    
    private var provider: AIModel.ModelProvider
    @Binding private var showAddModelSheet: Bool
    
    init(
        provider: AIModel.ModelProvider,
        showAddModelSheet: Binding<Bool>
    ) {
        self.provider = provider
        self._showAddModelSheet = showAddModelSheet
    }
    
    // MARK: - States
    
    @State private var modelName: String = ""
    @State private var displayName: String = ""
    @State private var supportsVision: Bool = false
    @State private var supportsSystemPrompts: Bool = false
    @State private var supportsToolCalling: Bool = false
    
    @State private var verifyingModel: Bool = false
    @State private var submitDisabled: Bool = true
    @State private var errorMessage: String = ""
    
    @State private var showRemovedRemoteModels: Bool = false
    @State private var removedRemoteModelsSearchQuery: String = ""
    
    // MARK: - Private Variables
    
    private var filteredUserRemovedRemoteModels: [AIModel] {
        let removedRemoteModels = userRemovedRemoteModels.filter{ $0.provider == provider }
        
        if removedRemoteModelsSearchQuery.isEmpty {
            return removedRemoteModels
        } else {
            return removedRemoteModels.filter({ $0.displayName.lowercased().contains(removedRemoteModelsSearchQuery.lowercased())} )
        }
    }
    
    private let spacingBetweenRemovedModelsButtons: CGFloat = 2
    
    private var removedRemoteModelsViewScrollHeight: CGFloat {
        let totalSpacingHeight: CGFloat =
            filteredUserRemovedRemoteModels.isEmpty ? 0 :
            spacingBetweenRemovedModelsButtons * CGFloat(filteredUserRemovedRemoteModels.count - 1)
        
        let totalButtonsHeight: CGFloat = ButtonConstants.textButtonHeight * CGFloat(filteredUserRemovedRemoteModels.count)
        
        return min(260, totalSpacingHeight + totalButtonsHeight)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text("Add a new model")
                    .styleText(size: 13)
                    .truncateText()
                
                Spacer()
                
                SimpleButton(text: "Removed Models") {
                    showRemovedRemoteModels.toggle()
                }
                .popover(
                    isPresented: $showRemovedRemoteModels,
                    arrowEdge: .bottom
                ) {
                    removedRemoteModelsView
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                inputField(
                    title: "Model Name *",
                    placeholder: "gpt-4o-mini-07-18-2024",
                    text: $modelName
                )
                
                inputField(
                    title: "Display Name",
                    placeholder: "GPT-4o Mini",
                    text: $displayName
                )
                
                toggleSection(
                    text: "Supports Vision",
                    isOn: $supportsVision
                )
                
                toggleSection(
                    text: "Supports System Prompts",
                    isOn: $supportsSystemPrompts
                )
                
                toggleSection(
                    text: "Supports Tool Calling",
                    isOn: $supportsToolCalling
                )
            }
            
            if !errorMessage.isEmpty {
                errorMessageView
            }
            
            HStack(alignment: .center, spacing: 8) {
                Spacer()
                
                SimpleButton(text: "Cancel") {
                    showAddModelSheet = false
                }
                
                SimpleButton(
                    isLoading: verifyingModel,
                    text: "Verify & Add",
                    action: {
                        Task {
                            await verifyAndAdd()
                        }
                    },
                    background: .blue
                )
                .disabled(submitDisabled)
                .allowsHitTesting(!submitDisabled)
                .opacity(submitDisabled ? 0.5 : 1)
                .addAnimation(dependency: submitDisabled)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 330)
        .onChange(of: modelName) { _, newModelName in
            submitDisabled = newModelName.isEmpty
        }
        .onChange(of: verifyingModel) { _, newVerifyingModel in
            submitDisabled = newVerifyingModel
        }
    }
    
    // MARK: - Child Components
    
    private func inputField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .styleText(
                    size: 11,
                    weight: .regular
                )
            
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .frame(height: 22)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)
        }
    }
    
    private func toggleSection(text: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text(text)
                .styleText(
                    size: 13,
                    weight: .regular
                )
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }
    
    private var errorMessageView: some View {
        HStack(alignment: .center, spacing: 4) {
            Image(.warningSettings)
            
            Text(errorMessage)
                .styleText(
                    size: 11,
                    weight: .regular,
                    color: .warning
                )
        }
    }
    
    private var removedRemoteModelsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            SearchBar(
                searchQuery: $removedRemoteModelsSearchQuery,
                placeholder: "Filter by display name",
                background: .clear
            )
            
            if filteredUserRemovedRemoteModels.isEmpty {
                Text("No models.")
                    .padding(.horizontal, 8)
                    .styleText(size: 13, color: .gray100)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: spacingBetweenRemovedModelsButtons) {
                        ForEach(filteredUserRemovedRemoteModels) { remoteModel in
                            TextButton(text: remoteModel.displayName) {
                                modelName = remoteModel.id
                                displayName = remoteModel.displayName
                                supportsVision = remoteModel.supportsVision
                                supportsSystemPrompts = remoteModel.supportsSystemPrompts
                                supportsToolCalling = remoteModel.supportsToolCalling
                                
                                showRemovedRemoteModels = false
                            }
                        }
                    }
                }
                .frame(height: removedRemoteModelsViewScrollHeight)
            }
        }
        .padding(8)
        .frame(width: 240)
    }
    
    // MARK: - Private Functions
    
    private func verifyRemoteModel(_ remoteModel: AIModel) async -> String? {
        let apiToken = TokenValidationManager.getTokenForModel(remoteModel)
        let useOnitServer = apiToken == nil || apiToken == ""
        
        do {
            _ = try await FetchingClient().chat(
                systemMessage: "Hi",
                instructions: ["Hi"],
                inputs: [nil],
                files: [[]],
                images: [[]],
                autoContexts: [[:]],
                webSearchContexts: [[]],
                responses: [],
                model: remoteModel,
                apiToken: apiToken,
                tools: [],
                useOnitServer: useOnitServer,
                includeSearch: nil
            )
            
            return nil
        } catch FetchingError.noContent {
            /// The provider endpoint may return no content. This is fine, because we only care that the endpoint returns a 200-level status code.
            /// Thus, we return `nil` here to indicate that the model name was valid.
            return nil
        } catch {
            return "Invalid model name."
        }
    }
    
    private func verifyAndAdd() async {
        errorMessage = ""
        
        verifyingModel = true
        defer { verifyingModel = false }
        
        guard let remoteModel = AIModel(
            from: ModelInfo(
                id: modelName,
                displayName: displayName.isEmpty ? modelName : displayName,
                provider: provider.rawValue,
                defaultOn: true,
                supportsVision: supportsVision,
                supportsSystemPrompts: supportsSystemPrompts,
                supportsToolCalling: supportsToolCalling
            )
        ) else {
            errorMessage = "Unable to verify model. Please try again."
            return
        }
        
        let remoteModelAlreadyAdded = availableRemoteModels.contains(where: { $0.uniqueId == remoteModel.uniqueId })
        
        if remoteModelAlreadyAdded {
            errorMessage = "Model already added."
        } else {
            guard let verificationErrorMessage = await verifyRemoteModel(remoteModel)
            else {
                appState.addRemoteModel(remoteModel)
                showAddModelSheet = false
                return
            }
            
            errorMessage = verificationErrorMessage
        }
    }
}
