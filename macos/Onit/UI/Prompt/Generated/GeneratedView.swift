//
//  GeneratedView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import SwiftUI

struct GeneratedView: View {
    @Environment(\.model) var model

    var body: some View {
        content
            .frame(minHeight: 350)
            // maxHeight: NSScreen.main?.frame.height ?? 750)
    }

    var content: some View {
        VStack(spacing: 16) {
            if model.generationState == .generating && !model.streamedResponse.isEmpty {
                GeneratedContentView(stream: true)
            } else if let result = model.generation {
                GeneratedContentView(result: result)
            } else if model.generationState == .generating {
                GeneratingView()
            }
            GeneratedToolbar()
        }
        .padding(16)
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        GeneratedView()
    }
}
#endif
