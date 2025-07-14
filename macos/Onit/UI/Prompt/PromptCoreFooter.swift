//
//  PromptCoreFooter.swift
//  Onit
//
//  Created by Loyd Kim on 4/17/25.
//

import SwiftUI
import Defaults

struct PromptCoreFooter: View {
    @Environment(\.windowState) private var windowState
    @Default(.mode) private var mode
    @Default(.allowWebSearchInLocalMode) private var allowWebSearchInLocalMode
    
    private let audioRecorder: AudioRecorder
    private let disableSend: Bool
    private let handleSend: () -> Void
    
    init(
        audioRecorder: AudioRecorder,
        disableSend: Bool,
        handleSend: @escaping () -> Void
    ) {
        self.audioRecorder = audioRecorder
        self.disableSend = disableSend
        self.handleSend = handleSend
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 4) {
                ModelSelectionButton(mode: mode)
                
                if mode != .local || allowWebSearchInLocalMode {
                    WebSearchButton()
                }
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                MicrophoneButton(audioRecorder: audioRecorder)
                
                PromptCoreFooterButton(
                    iconColor: .gray200,
                    icon: .send2,
                    text: "Send",
                    disabled: disableSend,
                    action: handleSend
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}
