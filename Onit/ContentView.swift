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
            Color.gray700.frame(height: 1)
            TextInputView()
        }
        .background(Color.black)
        .frame(minWidth: 400)
        .onAppear {
            for window in NSApplication.shared.windows {
                window.level = .floating
            }
        }
    }
}

#Preview {
    ContentView()
}
