//
//  ContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.model) var model

    var body: some View {
        VStack(spacing: 0) {
            Toolbar()
            divider
            input
            TextInputView()
            content
        }
        .background(Color.black)
        .buttonStyle(.plain)
        .frame(minWidth: 400)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.gray600, lineWidth: 2)
        }
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
            divider
            GeneratingView()
        case .generated(let result):
            divider
            GeneratedView(result: result)
        case .error(let error):
            GeneratedErrorView(error: error)
        default:
            EmptyView()
        }
    }

    var divider: some View {
        Color.gray600
            .frame(height: 1)
    }
}

#Preview {
    ContentView()
        .environment(OnitModel())
}
