//
//  RemoteModelsSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct RemoteModelsSection: View {
    @Environment(\.appState) var appState

    var body: some View {
        ScrollView {
            ModelsSection(title: "Remote Models") {
                RemoteModelSection(provider: .openAI)
                RemoteModelSection(provider: .anthropic)
                RemoteModelSection(provider: .xAI)
                RemoteModelSection(provider: .googleAI)
                RemoteModelSection(provider: .deepSeek)
                RemoteModelSection(provider: .perplexity)
                CustomProvidersSection()
            }
            .opacity(appState.isOnline ? 1 : 0.4)
            .allowsHitTesting(appState.isOnline)
        }
    }
}

#Preview {
    RemoteModelsSection()
}
