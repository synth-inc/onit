//
//  ContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            Toolbar()
            PromptDivider()
            PromptView()
        }
        .background(Color.black)
        .buttonStyle(.plain)
        .frame(minWidth: 400)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.gray600, lineWidth: 2)
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
