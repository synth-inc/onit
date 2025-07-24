//
//  ModelsTab.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct ModelsTab: View {
    @Environment(\.appState) var appState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                SettingsAuthCTA(
                    caption: "Create an account to access all remote providers and use models like GPT-4o, Gemini, Grok and more without API Keys."
                )
                
                RemoteModelsSection()
                LocalModelsSection()
                DefaultModelsSection()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 86)
        }
    }
}

#Preview {
    ModelsTab()
}
