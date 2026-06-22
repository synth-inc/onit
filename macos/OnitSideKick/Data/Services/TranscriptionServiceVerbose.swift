//
//  TranscriptionServiceVerbose.swift
//  Onit
//
//  Created by Loyd Kim on 6/16/25.
//

struct TranscriptionServiceVerbose: Codable {
    struct Segment: Codable {
        let id: Int
        let start: Double
        let end: Double
        let text: String
        let no_speech_prob: Double
        
        let tokens: [Int]?
        let seek: Int?
        let temperature: Double?
        let compression_ratio: Double?
        let avg_logprob: Double?
    }
    
    let segments: [Segment]
}
