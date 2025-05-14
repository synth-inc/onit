//
//  EmbeddingsService.swift
//  Onit
//
//  Created by Jason Swanson on 5/12/25.
//

import Foundation
import Embeddings
import Hub

@MainActor
class EmbeddingsService: ObservableObject {
    @Published var embeddings: [Embedding] = []
    
    private let maxStoredTexts = 10
    
    private var modelUrl: URL?
    
    init() {
        downloadModel()
    }
    
    func downloadModel() {
        Task {
            let hubApi = HubApi(downloadBase: nil, useBackgroundSession: false)
            let repo = Hub.Repo(id: "sentence-transformers/all-MiniLM-L6-v2", type: .models)
            modelUrl = try await hubApi.snapshot(
                from: repo,
                matching: [
                    "*.json",
                    "*.safetensors",
                    "*.py",
                    "tokenizer.model",
                    "sentencepiece*.model",
                    "*.tiktoken",
                    "*.txt",
                ]
            )
        }
    }
    
    @available(macOS 15.0, *)
    func storeText(_ text: String) async throws -> Void {
        let chunks = SentenceChunker.chunkIntoSentences(text)
        for chunk in chunks {
            embeddings.append(Embedding(id: UUID().uuidString, text: chunk, embedding: try await encodeText(chunk)))
        }
    }
    
    @available(macOS 15.0, *)
    func searchSimilarTexts(query: String, limit: Int = 10) async throws -> [(text: String, similarity: Float)] {
        let queryEmbedding = try await encodeText(query)
        var results: [(text: String, similarity: Float)] = []
        
        for stored in embeddings {
            let similarity = cosineSimilarity(queryEmbedding, stored.embedding)
            results.append((text: stored.text, similarity: similarity))
        }
        
        return results.sorted { $0.similarity > $1.similarity }.prefix(limit).map { $0 }
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        normA = sqrt(normA)
        normB = sqrt(normB)
        
        guard normA > 0 && normB > 0 else { return 0 }
        return dotProduct / (normA * normB)
    }
    
    @available(macOS 15.0, *)
    private func encodeText(_ text: String) async throws -> [Float] {
        var modelBundle: Bert.ModelBundle
        if let modelUrl = modelUrl {
            modelBundle = try await Bert.loadModelBundle(
                from: modelUrl
            )
        } else {
            modelBundle = try await Bert.loadModelBundle(
                from: "sentence-transformers/all-MiniLM-L6-v2"
            )
        }
        
        let encoded = try modelBundle.encode(text)
        let result = await encoded.cast(to: Float.self).shapedArray(of: Float.self).scalars
        return result
    }
}
