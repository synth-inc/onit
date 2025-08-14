//
//  GeneralTabVoice.swift
//  Onit
//
//  Created by Loyd Kim on 6/13/25.
//

import Defaults
import SwiftUI

struct GeneralTabVoice: View {
    @Default(.voiceSilenceThreshold) var voiceSilenceThreshold
    @Default(.voiceSpeechPassThreshold) var voiceSpeechPassThreshold
    
    var body: some View {
        SettingsSection(
            iconImage: .voice,
            title: "Voice",
            spacing: 4
        ) {
            ambientNoiseFilter
            confidenceThreshold
        }
    }
}

// MARK: - Child Components

extension GeneralTabVoice {
    var ambientNoiseFilter: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Ambient Noise Filter")
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
        .foregroundColor(Color.S_0)
    }
    
    var confidenceThreshold: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Confidence Threshold")
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
        .foregroundColor(Color.S_0)
    }
}
