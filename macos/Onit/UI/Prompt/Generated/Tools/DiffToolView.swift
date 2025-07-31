//
//  DiffToolView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/07/2025.
//

import Defaults
import SwiftUI

struct DiffToolView: View {
    @Default(.lineHeight) var lineHeight
    @Default(.fontSize) var fontSize
    
    let response: Response
    
    private var message: String {
        if response.isPartial {
            return "Streaming in Diff View..."
        } else {
            return "Content in Diff View"
        }
    }
    
    var body: some View {
        if response.shouldDisplayDiffToolView {
            toolView
        } else {
            previewText
        }
    }
    
    private var toolView: some View {
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
            
            Text(message)
                .foregroundStyle(.gray100)
                .padding(.leading, 2)
            
            Button {
                
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.gray200)
                    .frame(width: 16, height: 16)
            }
            .tooltip(prompt: "Diff view automatically activates\nwhen an iteration or edit is\ndetected.")
            .padding(.leading, 2)
            
            Spacer()
            
            Button {
                switchToChat()
            } label: {
                Text("Switch to Chat →")
                    .foregroundStyle(.FG)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.gray700)
        }
    }
    
    @ViewBuilder
    private var previewText: some View {
        if let diffPreview = response.diffPreview {
            Text(diffPreview)
                .textSelection(.enabled)
                .font(.system(size: fontSize))
                .lineSpacing(lineHeight)
                .foregroundStyle(.FG)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func switchToChat() {
        NotepadWindowController.shared.closeWindow()
        response.shouldDisplayDiffToolView = false
    }
}
