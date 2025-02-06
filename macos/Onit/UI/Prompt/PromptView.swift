//
//  PromptView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct PromptView: View {

    @ObservedObject var prompt: Prompt

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.bottom, 16)
    }

    @ViewBuilder
    var content: some View {
        switch prompt.generationState {
        case .generating:
            GeneratingView(prompt: prompt)
        case .done:
            GeneratedView(prompt: prompt)
        default:
            EmptyView()
        }
    }
}

#Preview {
    // TODO bring back the previews..
    //      PromptView()
}
