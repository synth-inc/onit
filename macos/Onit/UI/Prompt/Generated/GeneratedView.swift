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
    }

    var content: some View {
        VStack(spacing: 16) {
            if let result = model.generation {
                GeneratedContentView(result: result)
            }
            GeneratedToolbar()
                .padding([.bottom, .horizontal], 16)
        }
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        GeneratedView()
    }
}
#endif
