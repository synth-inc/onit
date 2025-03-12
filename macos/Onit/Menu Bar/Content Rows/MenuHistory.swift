//
//  MenuHistory.swift
//  Onit
//
//  Created by Alex on 3/13/24.
//

import SwiftUI

struct MenuHistory: View {
    @Environment(\.model) var model
    @Binding var isPresented: Bool
    
    var body: some View {
        Group {
            HStack {
                Text("History")
                    .font(.system(size: 13))
                Spacer()
                Image(systemName: "clock.fill")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            }
            .frame(height: 22)
            .padding(.horizontal, 10)
            .background {
                Button {
                    withAnimation {
                        isPresented.toggle()
                    }
                    // Stop event propagation
                    NSApp.stopModal()
                } label: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(MenuButtonStyle())
            }
        }
    }
}

#Preview {
    MenuHistory(isPresented: .constant(false))
}
