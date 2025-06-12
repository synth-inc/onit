//
//  WhisperServiceVerbose.swift
//  Onit
//
//  Created by Loyd Kim on 6/12/25.
//

struct WhisperServiceVerbose: Codable {
    struct Segment: Codable {
        let start: Double
        let end: Double
        let text: String
        let no_speech_prob: Double
    }
    
    let text: String
    let segments: [Segment]
    
    // Requiring 70% speech confidence to pass.
    static let requiredSpeechConfidenceInterval = 0.7
}
