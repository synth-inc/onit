//
//  CopyButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/28/24.
//

import SwiftUI

struct CopyButton: View {
    var text: String

    @State var showCheckmark = false

    var body: some View {
        Button {
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(text, forType: .string)
            showCheckmark = true

            Task {
                try await Task.sleep(for: .seconds(2))
                showCheckmark = false
            }
        } label: {
            Image(.copy)
                .renderingMode(.template)
                .padding(4)
                .opacity(showCheckmark ? 0 : 1)
                .overlay {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                        .opacity(showCheckmark ? 1 : 0)
                }
        }
        .buttonStyle(HoverableButtonStyle())
        .animation(.default, value: showCheckmark)
    }
}

#Preview {
    CopyButton(text: "Hello world")
}