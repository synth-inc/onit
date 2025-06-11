//
//  PromptCoreFooter.swift
//  Onit
//
//  Created by Loyd Kim on 4/17/25.
//

import SwiftUI

struct PromptCoreFooter: View {
    private let audioRecorder: AudioRecorder
    private let sendDisabled: Bool
    private let handleSend: () -> Void
    
    init(
        audioRecorder: AudioRecorder,
        sendDisabled: Bool,
        handleSend: @escaping () -> Void
    ) {
        self.audioRecorder = audioRecorder
        self.sendDisabled = sendDisabled
        self.handleSend = handleSend
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
                    disabled: sendDisabled,
                    action: handleSend
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}
