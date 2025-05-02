//
//  WaveformIndicator.swift
//  Onit
//
//  Created by OpenHands on 3/17/2025.
//

import SwiftUI

struct RecordingIndicator: View {
    @ObservedObject var audioRecorder: AudioRecorder

    var body: some View {
        Group {
            if audioRecorder.isTranscribing {
                LoadingIndicator()
            } else {
                if audioRecorder.isRecording {
                    WaveformIndicator(audioLevel: audioRecorder.audioLevel)
                }
            }
        }
        .onChange(of: audioRecorder.isTranscribing) {
            // Redraw the view when isTranscribing changes
        }
    }
}

struct WaveformIndicator: View {
    var audioLevel: Float
    
    private let numberOfBars = 4
    private let animationDuration = 0.6
    private let minHeight: CGFloat = 2
    private let maxHeight: CGFloat = 14
    @State private var barVariations: [Double] = []

    init(audioLevel: Float = 0.0) {
        self.audioLevel = audioLevel
        self._barVariations = State(initialValue: Array(repeating: 1.0, count: 4))
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<numberOfBars, id: \.self) { index in
                bar(for: index)
            }
        }
        .frame(height: 22)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(Color.red.opacity(0.2))
        )
        .onAppear {
            withAnimation(.linear(duration: animationDuration).repeatForever(autoreverses: false)) {
            }
        }
    }
    private func bar(for index: Int) -> some View {
        return RoundedRectangle(cornerRadius: 1)
            .fill(Color.red)
            .frame(width: 2, height: barHeight(for: index))
            .animation(
                .easeInOut(duration: 0.1), // Quick response to audio changes
                value: audioLevel
            )
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        // Base height is determined by the audio level
        let baseHeight = minHeight + (maxHeight - minHeight) * CGFloat(audioLevel)
        

        // Add some variation between bars to make it look more natural
        let newVariation = Double.random(in: 0.5...1.2)
        var newVariations = barVariations
        newVariations[index] = barVariations[index] * 0.8 + newVariation * 0.2
        DispatchQueue.main.async {
            barVariations = newVariations
        }
        
        return baseHeight * CGFloat(newVariations[index])
    }
}

struct LoadingIndicator: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11)
                .fill(Color.blue400.opacity(0.2))
                .frame(width: 22, height: 22)
            
            Color.blue400.mask {
                Loader()
            }
            .frame(width: 16, height: 16)
        }
    }
}



#Preview {
    VStack(spacing: 20) {
        RecordingIndicator(audioRecorder: AudioRecorder())
        LoadingIndicator()
    }
    .padding()
    .background(Color.black)
}
