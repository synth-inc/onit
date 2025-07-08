//
//  DiffToolView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/07/2025.
//

import SwiftUI

struct DiffToolView: View {
    let response: Response
    
    @Environment(\.windowState) private var windowState
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.redPale400.opacity(0.22))
                    .frame(width: 18, height: 18)
                Text("-")
                    .appFont(.medium14)
                    .foregroundStyle(.redPale400)
                    .frame(alignment: .center)
            }
            
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.limeGreen.opacity(0.22))
                    .frame(width: 18, height: 18)
                Text("+")
                    .appFont(.medium14)
                    .foregroundStyle(.limeGreen)
                    .frame(alignment: .center)
            }
            
            Text("Content in Diff View")
                .foregroundStyle(.gray100)
                .padding(.leading, 2)
            
            Button {
                infoTapped()
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.gray200)
                    .frame(width: 16, height: 16)
            }
            .padding(.leading, 2)
            
            Spacer()
            
            Button {
                showDiffTapped()
            } label: {
                Text("Show Diff")
                    .foregroundStyle(.FG)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.gray700)
        }
    }
    
    private func infoTapped() {
        log.error("Info tapped")
		// TODO: KNA - Diff view
    }
    
    private func showDiffTapped() {
        NotepadWindowController.shared.showWindow(windowState: windowState, response: response)
    }
}
