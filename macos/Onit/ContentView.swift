//
//  ContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.model) var model

    var maxHeight: CGFloat? {
        if let height = NSScreen.main?.visibleFrame.height {
            return height - 16 * 2
        } else {
            return nil
        }
    }

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
        .frame(minWidth: 325, idealWidth: 400)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.gray600, lineWidth: 2)
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.frame(in: .global)) {
                        print(proxy.frame(in: .global))
                    }
            }
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
