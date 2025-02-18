//
//  AutoCompleteView.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import SwiftUI

struct AutoCompleteView: View {
    @Environment(\.autoCompleteState) var state
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if state.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
            
            autoCompleteText
            
            if !state.isLoading && !state.completion.isEmpty{
                shortcutView
                menuButton
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(rgba: 0x1B1B1F))
                .stroke(.gray500, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private var autoCompleteText: some View {
        Text(state.completion)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.gray100)
    }
    
    private var shortcutView: some View {
        Text("TAB")
            .font(.system(size: 8, weight: .medium))
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.gray400, lineWidth: 1)
            )
    }
    
    private var menuButton: some View {
        Button {
            displayMenu()
        } label: {
            Image(.moreHorizontal)
                .resizable()
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(90))
        }
        .buttonStyle(.plain)
    }
    
    private func displayMenu() {
        // TODO: KNA
    }
}

#Preview {
    AutoCompleteView()
}
