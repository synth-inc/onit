//
//  RemoteModelRemoveModel.swift
//  Onit
//
//  Created by Loyd Kim on 7/21/25.
//

import Defaults
import SwiftUI

struct RemoteModelRemoveModel: View {
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.userRemovedRemoteModels) var userRemovedRemoteModels
    
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
    
    // MARK: - Private Variables
    
    private var remoteModels: [AIModel] {
        availableRemoteModels.filter { $0.provider == self.provider }
    }
    
    private var noSelectedRemoteModels: Bool {
        selectedRemoteModels.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Remove added models")
                .styleText(size: 13)
                .truncateText()
            
            DynamicScrollView(maxHeight: 260) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(remoteModels) { remoteModel in
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
                    action: removeSelectedRemoteModels,
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
    
    // MARK: - Private Functions
    
    private func removeSelectedRemoteModels() {
        let userRemovedRemoteModelUniqueIds = Set(userRemovedRemoteModels.map { $0.uniqueId })
        
        for selectedRemoteModel in selectedRemoteModels {
            if !userRemovedRemoteModelUniqueIds.contains(selectedRemoteModel.uniqueId) {
                userRemovedRemoteModels.append(selectedRemoteModel)
            }
        }
        
        let selectedRemoteModelUniqueIds = Set(selectedRemoteModels.map { $0.uniqueId })
        
        availableRemoteModels.removeAll { selectedRemoteModelUniqueIds.contains($0.uniqueId) }
        
        showRemoveModelsSheet = false
    }
}
