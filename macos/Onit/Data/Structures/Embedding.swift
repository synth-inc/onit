//
//  Embedding.swift
//  Onit
//
//  Created by Jason Swanson on 5/13/25.
//

struct Embedding: Identifiable {
    let id: String
    let text: String
    let embedding: [Float]

    var embeddingString: String {
        return embedding.map { String($0) }.joined(separator: ", ")
    }
}
