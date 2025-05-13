//
//  PromptCoreFooter.swift
//  Onit
//
//  Created by Loyd Kim on 4/17/25.
//

import SwiftUI

struct PromptCoreFooter: View {
    @Binding private var isPressedModelSelectionButton: Bool
    @Binding private var promptText: String
    @Binding private var cursorPosition: Int
    private let audioRecorder: AudioRecorder
    private let sendDisabled: Bool
    private let sendAction: () -> Void
    private let isEditing: Bool
    
    init(
        isPressedModelSelectionButton: Binding<Bool>,
        promptText: Binding<String>,
        cursorPosition: Binding<Int>,
        audioRecorder: AudioRecorder,
        sendDisabled: Bool = false,
        sendAction: @escaping () -> Void,
        isEditing: Bool
    ) {
        self._isPressedModelSelectionButton = isPressedModelSelectionButton
        self._promptText = promptText
        self._cursorPosition = cursorPosition
        self.audioRecorder = audioRecorder
        self.sendDisabled = sendDisabled
        self.sendAction = sendAction
        self.isEditing = isEditing
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 4) {
                ModelSelectionButton(
                    isPressedModelSelectionButton: $isPressedModelSelectionButton
                )
                
                WebSearchButton()
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                MicrophoneButton(
                    promptText: $promptText,
                    cursorPosition: $cursorPosition,
                    audioRecorder: audioRecorder
                )
                
                PromptCoreFooterButton(
                    text: "􀅇 Send",
                    disabled: sendDisabled,
                    action: sendAction
                )
                .allowsHitTesting(!sendDisabled)
            }
        }
        .padding(.horizontal, isEditing ? 0 : 12)
        .padding(.bottom, isEditing ? 0 : 12)
    }
}
