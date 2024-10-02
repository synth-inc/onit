//
//  ContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import SwiftUI

struct ContentView: View {
    var panelManager: PanelManager

    var body: some View {
        VStack(spacing: 0) {
            Toolbar()
            Color.gray700.frame(height: 1)
            TextInputView()
        }
        .background(Color.black)
        .frame(minWidth: 400)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.gray700, lineWidth: 2)
        }
    }
}

#Preview {
    ContentView(panelManager: .init())
}
