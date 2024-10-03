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
            TextInputView()
            content
        }
        .background(Color.black)
        .buttonStyle(.plain)
        .frame(minWidth: 400)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.gray700, lineWidth: 2)
        }
    }

    @ViewBuilder
    var content: some View {
        switch model.generationState {
        case .generating:
            divider
            GeneratingView()
        case .generated(let result):
            GeneratedView(result: result)
        default:
            EmptyView()
        }
    }

    var divider: some View {
        Color.gray700.frame(height: 1)
    }
}

#Preview {
    ContentView()
        .environment(Model())
}
