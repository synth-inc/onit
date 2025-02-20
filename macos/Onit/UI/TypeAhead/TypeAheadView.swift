//
//  TypeAheadView.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import SwiftUI

struct TypeAheadView: View {
    @Environment(\.model) var model
    @Environment(\.openSettings) var openSettings
    @Environment(\.typeAheadState) var state
    
    @State var showMenu = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            if state.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
            
            errorOrCompletion
            
            if !state.isLoading && !state.completion.isEmpty{
                shortcutView
                menuButton
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(.typeAheadBG)
                .stroke(.gray500, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private var errorOrCompletion: some View {
        Group {
            if let error = state.error {
                if error == .noModelConfigured {
                    Button {
                        model.setSettingsTab(tab: .accessibility)
                        openSettings()
                    } label: {
                        HStack {
                            Image(.settingsCog)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 16, height: 16)
                            Text(error.localizedDescription)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(error.localizedDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.red)
                }
            } else {
                Text(state.completion)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.gray100)
            }
        }
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
            showMenu.toggle()
        } label: {
            Image(.moreHorizontal)
                .resizable()
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(90))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showMenu) {
            TypeAheadMenuView()
        }
    }
}

#Preview {
    TypeAheadView()
}
