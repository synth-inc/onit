//
//  LocalModelsSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct LocalModelsSection: View {
    @Environment(\.model) var model

    @State private var isOn: Bool = false

    var body: some View {
        ModelsSection(title: "Local Models") {
            VStack(alignment: .leading, spacing: 10) {
                title
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            isOn = model.useLocal
        }
        .onChange(of: isOn) {
            model.useLocal = isOn
        }
    }

    var title: some View {
        ModelTitle(title: "Ollama", isOn: $isOn)
    }

    @ViewBuilder
    var content: some View {
        if model.availableLocalModels.isEmpty {
            HStack(spacing: 0) {
                text
                Spacer(minLength: 8)
                button
            }
        } else {
            modelsView
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

    @ViewBuilder
    var modelsView: some View {
        if isOn {
            GroupBox {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(model.availableLocalModels, id: \.self) { model in
                        Toggle(isOn: .constant(true)) {
                            Text(model)
                                .font(.system(size: 13))
                                .fontWeight(.regular)
                                .opacity(0.85)
                        }
                        .frame(height: 36)
                    }
                }
                .padding(.vertical, -4)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
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
