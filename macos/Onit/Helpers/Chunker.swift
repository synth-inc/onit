//
//  Chunker.swift
//  Onit
//
//  Created by Jason Swanson on 5/12/25.
//

import Foundation
import NaturalLanguage

public class Chunker {
    public static func chunkByUnit(_ text: String, unit: NLTokenUnit) -> [String] {
        let tokenizer = NLTokenizer(unit: unit)
        tokenizer.string = text
        
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { (tokenRange, _) -> Bool in
            tokens.append(String(text[tokenRange]))
            return true
        }
        return tokens
    }
}
