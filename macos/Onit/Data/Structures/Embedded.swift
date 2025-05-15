//
//  Embedded.swift
//  Onit
//
//  Created by Jason Swanson on 5/13/25.
//

import Foundation

struct EmbeddedDocument: Identifiable {
    let id: String = UUID().uuidString
    
    let text: String
}

struct EmbeddedParagraph: Identifiable {
    let id: String = UUID().uuidString
    let documentId: String
    
    let text: String
}

struct EmbeddedSentence: Identifiable {
    let id: String = UUID().uuidString
    let documentId: String
    let paragraphId: String
    
    let text: String
    let embedding: [Float]

    var embeddingString: String {
        return embedding.map { String($0) }.joined(separator: ", ")
    }
}
