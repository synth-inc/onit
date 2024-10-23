//
//  PromptView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct PromptView: View {
    @Environment(\.model) var model

    var body: some View {
        VStack(spacing: 0) {
            input
            FileRow()
            TextInputView()
            content
        }
        .drag()
    }

    @ViewBuilder
    var input: some View {
        if let input = model.input {
            InputView(input: input)
        }
    }

    @ViewBuilder
    var content: some View {
        switch model.generationState {
        case .generating:
            PromptDivider()
            GeneratingView()
        case .generated(let result):
            PromptDivider()
            GeneratedView(result: result)
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
