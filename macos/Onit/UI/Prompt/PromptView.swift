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
            FileRow()
            TextInputView()
            content
        }
        .drag()
    }

    @ViewBuilder
    var content: some View {
        switch model.generationState {
        case .generating:
            PromptDivider()
            GeneratingView()
        case .generated:
            PromptDivider()
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
