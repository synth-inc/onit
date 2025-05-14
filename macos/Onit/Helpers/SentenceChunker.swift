//
//  SentenceChunker.swift
//  Onit
//
//  Created by Jason Swanson on 5/12/25.
//

import Foundation

public class SentenceChunker {
    public static func chunkIntoSentences(_ text: String) -> [String] {
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        tagger.string = text
        
        var sentences: [String] = []
        
        let range = NSRange(location: 0, length: text.utf16.count)
        
        tagger.enumerateTags(in: range, unit: .sentence, scheme: .tokenType, options: []) { _, tokenRange, _ in
            if let sentence = text.substring(with: tokenRange) {
                let cleanedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanedSentence.isEmpty {
                    sentences.append(cleanedSentence)
                }
            }
        }
        
        return sentences
    }
}

private extension String {
    func substring(with nsRange: NSRange) -> String? {
        guard let range = Range(nsRange, in: self) else { return nil }
        return String(self[range])
    }
}
