//
//  ContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import SwiftUI

struct ContentView: View {
    @State var windowSet = false

    var body: some View {
        VStack(spacing: 0) {
            Toolbar()
            Color.gray700.frame(height: 1)
            TextInputView()
        }
        .background(Color.black)
        .frame(minWidth: 400)
        .onAppear {
            setWindow(.main) {
                guard !windowSet else { return }

                $0.level = .floating
                if $0.styleMask != [.resizable, .docModalWindow] {
                    print($0.styleMask)
                    $0.styleMask = [.resizable, .docModalWindow]
                }
                $0.isMovableByWindowBackground = true

                $0.titlebarAppearsTransparent = true
                $0.titleVisibility = .hidden

                $0.backgroundColor = .clear
                
                windowSet = true
            }
        }
    }
}

#Preview {
    ContentView()
}
