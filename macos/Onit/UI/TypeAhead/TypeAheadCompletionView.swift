//
//  TypeAheadCompletionView.swift
//  Onit
//
//  Created by Kévin Naudin on 20/02/2025.
//

import SwiftUI

struct TypeAheadCompletionView: View {
    @Environment(\.model) var model
    @Environment(\.openSettings) var openSettings
    
    private let globalState = TypeAheadState.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            if globalState.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
            
            errorOrCompletion
            
            if !globalState.isLoading && !globalState.completion.isEmpty{
                shortcutView
                menuButton
            }
        }
        .frame(minHeight: 30)
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.typeAheadBG)
                .stroke(.gray500, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var errorOrCompletion: some View {
        Group {
            if let error = globalState.error {
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
                Text(globalState.completion)
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
            globalState.showMenu.toggle()
        } label: {
            Image(.moreHorizontal)
                .resizable()
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(90))
        }
        .buttonStyle(.plain)
        .onChange(of: globalState.showMenu) { _, showMenu in
            if showMenu {
                TypeAheadWindowController.shared.showMenu()
            } else {
                TypeAheadWindowController.shared.hideMenu()
            }
        }
    }
}

#Preview {
    TypeAheadCompletionView()
}
