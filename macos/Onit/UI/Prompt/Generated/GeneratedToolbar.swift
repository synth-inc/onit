//
//  GeneratedToolbar.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Defaults
import SwiftUI

struct GeneratedToolbar: View {
    @Environment(\.windowState) private var state
    @Default(.mode) var mode

    var prompt: Prompt

    var body: some View {
        HStack(spacing: 8) {
            copy
            regenerate
            selector
            
            Spacer()
            
            if prompt.generationIndex >= 0 &&
                prompt.generationIndex < prompt.responses.count,
                let model = prompt.sortedResponses[prompt.generationIndex].model {
                Text("\(model)")
                    .foregroundColor(Color.gray300)
            }
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    var copy: some View {
        if let generation = prompt.generation {
            CopyButton(text: generation, stripMarkdown: true)
        }
    }

    var regenerate: some View {
        IconButton(
            icon: .arrowsSpin,
            action: {
                state.generate(prompt)
            },
            tooltipPrompt: "Retry"
        )
    }

    var more: some View {
        IconButton(
            icon: .moreHorizontal,
            action: { print("More") },
            tooltipPrompt: "More"
        )
    }

    @ViewBuilder
    var selector: some View {
        if prompt.responses.count > 1 {
            ToggleOutputsView(prompt: prompt)
                .padding(.trailing, 8)
        }
    }

    var insertShortcut: KeyboardShortcut {
        .init("y")
    }

    var insert: some View {
        Button {
            if prompt.generationIndex != -1 && !prompt.responses.isEmpty {
                let text = prompt.sortedResponses[prompt.generationIndex].text
                
                PanelStateCoordinator.shared.closePanel(for: state)
            } else {
                print("Not generated: \(prompt.generationState ?? .done)")
            }
        } label: {
            HStack(spacing: 4) {
                Text("Insert")
                    .appFont(.medium14)
                    .padding(.leading, 4)
                KeyboardShortcutView(shortcut: insertShortcut)
                    .appFont(.medium12)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 5)
                    .background {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(.blue350)
                    }
            }
            .padding(4)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(mode == .local ? .limeGreen : .blue400)
            }
            .foregroundStyle(.FG)
        }
        .keyboardShortcut(insertShortcut)
        .buttonStyle(.plain)
        .tooltip(
            prompt: "Send",
            shortcut: .keyboardShortcuts(.enter),
            background: false
        )
    }
}

#if DEBUG
    #Preview {
        // TODO bring 'em back
        //        GeneratedToolbar()
        //            .padding()
    }
#endif
