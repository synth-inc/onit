//
//  RemoteModelsSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct RemoteModelsSection: View {
    @Environment(\.model) var model

    var body: some View {
        ModelsSection(title: "Remote Models") {
            RemoteModelSection(provider: .openAI)
            RemoteModelSection(provider: .anthropic)
            RemoteModelSection(provider: .xAI)
            RemoteModelSection(provider: .googleAI)
        }
    }
}
