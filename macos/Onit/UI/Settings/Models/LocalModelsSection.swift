//
//  LocalModelsSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct LocalModelsSection: View {
    @State private var isOn: Bool = false

    var body: some View {
        ModelsSection(title: "Local Models") {
            VStack(alignment: .leading, spacing: 10) {
                title
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var title: some View {
        ModelTitle(title: "Ollama", isOn: $isOn)
    }

    var content: some View {
        HStack(spacing: 0) {
            text
            Spacer(minLength: 8)
            button
        }
    }

    var link: String {
        "[Download Ollama](https://ollama.com/download/mac)"
    }

    var text: some View {
        (
            Text(.init(link))
            +
            Text("""
     to use Onit with local models. Models running locally on Ollama will be available here
    """
            )
        )
        .foregroundStyle(.primary.opacity(0.65))
        .font(.system(size: 12))
        .fontWeight(.regular)
    }

    var button: some View {
        Button("Reload") {

        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    LocalModelsSection()
}
