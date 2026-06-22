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
        .padding(.bottom, 12)
    }

    @ViewBuilder
    var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            FinalContextView(prompt: prompt)
            
            switch prompt.generationState {
            case .generating:
                GeneratingView(prompt: prompt)
            case .streaming, .done:
                GeneratedView(prompt: prompt)
            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    // TODO bring back the previews..
    //      PromptView()
}
