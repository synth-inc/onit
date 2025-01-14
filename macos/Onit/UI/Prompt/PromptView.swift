//
//  PromptView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct PromptView: View {
    @Environment(\.model) var model

    @AppStorage("seenLocal") var seenLocal = false

    var body: some View {
        VStack(spacing: 0) {
            YouSaidView()
            content
            SetUpDialogs(seenLocal: seenLocal)
            FileRow()
            TextInputView()
        }
        .drag()
        .onChange(of: model.availableLocalModels.count) { _, new in
            if new != 0 {
                seenLocal = true
            }
        }
    }

    @ViewBuilder
    var content: some View {
        switch model.generationState {
        case .generating:
            PromptDivider()
            GeneratingView()
        case .generated:
            GeneratedView()
        case .error(let error):
            GeneratedErrorView(error: error)
        default:
            EmptyView()
        }
    }
}

#Preview {
    PromptView()
}
