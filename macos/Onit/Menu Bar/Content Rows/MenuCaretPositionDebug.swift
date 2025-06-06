//
//  MenuCaretPositionDebug.swift
//  Onit
//
//  Created by Kévin Naudin on 06/06/2025.
//

import SwiftUI

// TODO: KNA - Should be removed after debugging
struct MenuCaretPositionDebug: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        #if DEBUG
        Button {
            openWindow(id: "caretPosition")
        } label: {
            HStack {
                Image(systemName: "cursor.rays")
                Text("Debug Caret Position")
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        #endif
    }
}

#Preview {
    MenuCaretPositionDebug()
} 
