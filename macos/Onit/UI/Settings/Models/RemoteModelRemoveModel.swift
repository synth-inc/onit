//
//  RemoteModelRemoveModel.swift
//  Onit
//
//  Created by Loyd Kim on 7/21/25.
//

import Defaults
import SwiftUI

struct RemoteModelRemoveModel: View {
    @Environment(\.appState) var appState
    
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.userRemovedRemoteModels) var userRemovedRemoteModels
    @Default(.userAddedRemoteModels) var userAddedRemoteModels
    
    // MARK: - Properties
    
    private var provider: AIModel.ModelProvider
    @Binding private var showRemoveModelsSheet: Bool
    
    init(
        provider: AIModel.ModelProvider,
        showRemoveModelsSheet: Binding<Bool>
    ) {
        self.provider = provider
        self._showRemoveModelsSheet = showRemoveModelsSheet
    }
    
    // MARK: - States
    
    @State private var selectedRemoteModels: [AIModel] = []
    @State private var searchQuery: String = ""
    
    // MARK: - Private Variables
    
    private var remoteModels: [AIModel] {
        availableRemoteModels.filter { $0.provider == self.provider }
    }
    
    private var filteredRemoteModels: [AIModel] {
        if searchQuery.isEmpty {
            remoteModels
        } else {
            remoteModels.filter { $0.displayName.lowercased().contains(searchQuery.lowercased()) }
        }
    }
    
    private var selectedAll: Bool {
        filteredRemoteModels.allSatisfy { selectedRemoteModels.contains($0) }
    }
    
    private var noSelectedRemoteModels: Bool {
        selectedRemoteModels.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("Remove added models")
                    .styleText(size: 13)
                    .truncateText()
                
                Spacer()
                
                SimpleButton(
                    text: "\(selectedAll ? "Unselect" : "Select") All",
                    action: {
                        if selectedAll {
                            selectedRemoteModels.removeAll { filteredRemoteModels.contains($0) }
                        } else {
                            selectedRemoteModels = filteredRemoteModels
                        }
                    }
                )
            }
            
            SearchBar(
                searchQuery: $searchQuery, 
                placeholder: "Filter by display name",
                background: .clear
            )
            
            DynamicScrollView(maxHeight: 260) {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredRemoteModels) { remoteModel in
                        modelToggleButton(remoteModel)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            HStack(alignment: .center, spacing: 8) {
                Spacer()
                
                SimpleButton(text: "Cancel") {
                    showRemoveModelsSheet = false
                }
                
                SimpleButton(
                    text: "Remove Selected",
                    textColor: .red,
                    action: {
                        appState.removeRemoteModels(selectedRemoteModels)
                        showRemoveModelsSheet = false
                    },
                    background: .redBrick
                )
                .opacity(noSelectedRemoteModels ? 0.5 : 1)
                .disabled(noSelectedRemoteModels)
                .allowsHitTesting(!noSelectedRemoteModels)
                .addAnimation(dependency: noSelectedRemoteModels)
            }
        }
        .padding(20)
        .frame(width: 330)
    }
    
    // MARK: - Child Components
    
    private func modelToggleButton(_ remoteModel: AIModel) -> some View {
        Toggle(isOn: Binding(
            get: { selectedRemoteModels.contains(remoteModel) },
            set: { isSelected in
                if isSelected {
                    if !selectedRemoteModels.contains(remoteModel) {
                        selectedRemoteModels.append(remoteModel)
                    }
                } else {
                    selectedRemoteModels.removeAll { $0 == remoteModel }
                }
            }
        )) {
            Text(remoteModel.displayName)
                .styleText(size: 13, weight: .regular)
                .opacity(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 36)
    }
}
