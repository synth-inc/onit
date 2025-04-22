//
//  PromptCoreFooter.swift
//  Onit
//
//  Created by Loyd Kim on 4/17/25.
//

import SwiftUI

struct PromptCoreFooter: View {
    @Environment(\.windowState) private var windowState
    
    private let audioRecorder: AudioRecorder
    
    init(audioRecorder: AudioRecorder) {
        self.audioRecorder = audioRecorder
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 4) {
                ModelSelectionButton()
                WebSearchButton()
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                MicrophoneButton(audioRecorder: audioRecorder)
                PromptCoreFooterButton(
                    text: "􀅇 Send",
                    disabled: windowState.pendingInstruction.isEmpty,
                    action: { windowState.sendAction() }
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

// MARK: - Child Components

extension PromptCoreFooter {
    private func iconButton(
        icon: ImageResource,
        action: @escaping () -> Void
    ) -> some View {
        IconButton(
            icon: icon,
            iconSize: 16,
            action: action
        )
    }
}
