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
            PromptDivider()
            PromptView()
        }
        .opacity(model.showHistory ? 0 : 1)
        .overlay {
            if model.showHistory {
                HistoryView()
            }
        }
        .background(Color.black)
        .buttonStyle(.plain)
        .frame(minWidth: 400)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.gray600, lineWidth: 2)
        }
        .overlay {
            
        }
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        ContentView()
    }
}
#endif
