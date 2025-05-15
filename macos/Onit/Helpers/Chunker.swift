//
//  Chunker.swift
//  Onit
//
//  Created by Jason Swanson on 5/12/25.
//

import Foundation

public class Chunker {
    public static func chunkByUnit(_ text: String, unit: NSLinguisticTaggerUnit) -> [String] {
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        tagger.string = text
        
        var chunks: [String] = []
        
        let range = NSRange(location: 0, length: text.utf16.count)
        
        tagger.enumerateTags(in: range, unit: unit, scheme: .tokenType, options: []) { _, tokenRange, _ in
            if let chunk = text.substring(with: tokenRange) {
                let cleanedChunk = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanedChunk.isEmpty {
                    chunks.append(cleanedChunk)
                }
            }
        }
        
        return chunks
    }
}

private extension String {
    func substring(with nsRange: NSRange) -> String? {
        guard let range = Range(nsRange, in: self) else { return nil }
        return String(self[range])
    }
}
