//
//  GeneratedToolbar.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import SwiftUI

struct GeneratedToolbar: View {
    @Environment(\.model) var model

    var body: some View {
        HStack(spacing: 8) {
            copy
            regenerate
            more
            Spacer()
            selector
        }
        .foregroundStyle(.FG)
    }

    @ViewBuilder
    var copy: some View {
        if let generation = model.generation {
            CopyButton(text: generation)
        }
    }

    var regenerate: some View {
        Button {
            model.save(model.instructions)
            model.generate(model.instructions)
        } label: {
            Image(.arrowsSpin)
                .padding(4)
        }
        .tooltip(prompt: "Retry")
    }

    var more: some View {
        Button {

        } label: {
            Image(.moreHorizontal)
                .padding(4)
        }
        .tooltip(prompt: "More")
    }

    @ViewBuilder
    var selector: some View {
        if let count = model.generationCount, count > 1 {
            ToggleOutputsView()
                .padding(.trailing, 8)
        }
    }

    // Removed insert functionality
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        GeneratedToolbar()
            .padding()
    }
}
#endif
