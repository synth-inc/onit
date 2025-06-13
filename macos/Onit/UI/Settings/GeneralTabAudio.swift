//
//  GeneralTabAudio.swift
//  Onit
//
//  Created by Loyd Kim on 6/13/25.
//

import Defaults
import SwiftUI

struct GeneralTabAudio: View {
    @Default(.voiceSilenceThreshold) var voiceSilenceThreshold
    @Default(.voiceSpeechPassThreshold) var voiceSpeechPassThreshold
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Voice Silence Threshold")
                Slider(
                    value: $voiceSilenceThreshold,
                    in: -100...0,
                    step: 10
                )
                Text(String(Int(voiceSilenceThreshold)))
                    .monospacedDigit()
                    .frame(width: 40)
            }
            
            HStack {
                Spacer()
                Button("Restore Default") {
                    voiceSilenceThreshold = -40
                }
                .controlSize(.small)
            }
        }
        
        VStack(spacing: 8) {
            HStack {
                Text("Voice Speech Pass Threshold")
                Slider(
                    value: $voiceSpeechPassThreshold,
                    in: 0...1,
                    step: 0.1
                )
                Text(String(format: "%.1f", voiceSpeechPassThreshold))
                    .monospacedDigit()
                    .frame(width: 40)
            }
            
            HStack {
                Spacer()
                Button("Restore Default") {
                    voiceSpeechPassThreshold = 0.7
                }
                .controlSize(.small)
            }
        }
    }
}
