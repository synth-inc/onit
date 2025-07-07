//
//  AuthAddModelSection.swift
//  Onit
//
//  Created by Loyd Kim on 7/7/25.
//

import Defaults
import SwiftUI

struct AuthAddModelSection: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings
    
    // MARK: - States
    
    @State private var isHoveredAddLocalModelButton: Bool = false
    @State private var isHoveredAddModelButton: Bool = false
    
    @State private var isFetchingLocalModels: Bool = false
    
    @State private var errorMessageFetchingLocalModels: String = ""
    
    // MARK: - Private Variables
    
    private var isOffline: Bool {
        !appState.isOnline
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("Have local models\(!isOffline ? " or API key" : "")?")
                .styleText(
                    size: 13,
                    weight: .regular,
                    color: .gray100,
                    align: .center
                )
            
            loadLocalModelsButton
            
            fetchingLocalModelsError
            
            if !isOffline {
                openModelSettingsTabButton
            } else {
                if !errorMessageFetchingLocalModels.isEmpty {
                    openModelSettingsTabButton
                }
            }
        }
    }
    
    // MARK: - Child Components
    
    @ViewBuilder
    private var loadLocalModelsButton: some View {
        if isOffline {
            Button {
                isFetchingLocalModels = true
                errorMessageFetchingLocalModels = ""
                
                Task {
                    Defaults[.localEndpointURL] = URL(string: ModelConstants.ollamaUrl)!
                    
                    await appState.fetchLocalModels()
                    
                    if appState.localFetchFailed {
                        errorMessageFetchingLocalModels = "Failed to load Ollama.\nMake sure it is running and try again. Or manually add it with the link below."
                    } else {
                        errorMessageFetchingLocalModels = ""
                    }
                    
                    isFetchingLocalModels = false
                }
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    if isFetchingLocalModels {
                        Loader()
                    }
                    
                    Text("Load Ollama")
                        .styleText(
                            size: 13,
                            weight: .regular,
                            align: .center,
                            underline: isHoveredAddLocalModelButton
                        )
                        .onHover { isHovering in
                            isHoveredAddLocalModelButton = isHovering
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    private var fetchingLocalModelsError: some View {
        if !errorMessageFetchingLocalModels.isEmpty {
            Text(errorMessageFetchingLocalModels)
                .styleText(
                    size: 13,
                    weight: .regular,
                    color: .red,
                    align: .center
                )
                .frame(maxWidth: 220)
        }
    }
    
    private var openModelSettingsTabButton: some View {
        Button {
            appState.openModelSettingsTab(openSettings)
        } label: {
            Text("Add \(isOffline ? "local model" : "models") here to access Onit")
                .styleText(
                    size: 13,
                    weight: .regular,
                    align: .center,
                    underline: isHoveredAddModelButton
                )
                .onHover { isHovering in
                    isHoveredAddModelButton = isHovering
                }
        }
    }
}
