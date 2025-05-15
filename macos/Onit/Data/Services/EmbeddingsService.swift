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
    var documentsQueue: [String] = []
    var documents: [String: EmbeddedDocument] = [:]
    var paragraphs: [String: EmbeddedParagraph] = [:]
    @Published var sentences: [EmbeddedSentence] = []
    
    let memoryLength: Int
    
    private var modelUrl: URL?
    
    init(memoryLength: Int = 10) {
        self.memoryLength = memoryLength
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
        if self.documentsQueue.count >= self.memoryLength {
            removeOldestDocument()
        }
        
        let embeddedDocument = EmbeddedDocument(text: text)
        
        let paragraphs = Chunker.chunkByUnit(text, unit: .paragraph)
        var embeddedParagraphs: [EmbeddedParagraph] = []
        
        var embeddedSentences: [EmbeddedSentence] = []
        
        for paragraph in paragraphs {
            let embeddedParagraph = EmbeddedParagraph(documentId: embeddedDocument.id, text: paragraph)
            embeddedParagraphs.append(embeddedParagraph)
            
            let sentences = Chunker.chunkByUnit(paragraph, unit: .sentence)
            for sentence in sentences {
                embeddedSentences.append(EmbeddedSentence(documentId: embeddedDocument.id, paragraphId: embeddedParagraph.id, text: sentence, embedding: try await encodeText(sentence)))
            }
        }
        
        self.documentsQueue.append(embeddedDocument.id)
        
        self.documents[embeddedDocument.id] = embeddedDocument
        
        for embeddedParagraph in embeddedParagraphs {
            self.paragraphs[embeddedParagraph.id] = embeddedParagraph
        }
        
        self.sentences.append(contentsOf: embeddedSentences)
    }
    
    private func removeOldestDocument() {
        let oldestDocument = self.documentsQueue.removeFirst()
        self.documents.removeValue(forKey: oldestDocument)
        for (paragraphId, paragraph) in self.paragraphs {
            if paragraph.documentId == oldestDocument {
                self.paragraphs.removeValue(forKey: paragraphId)
            }
        }
        self.sentences = self.sentences.filter { $0.documentId != oldestDocument }
    }
    
    enum Unit {
        case document
        case paragraph
        case sentence
    }
    
    @available(macOS 15.0, *)
    func searchSimilarTexts(query: String, unit: Unit = .paragraph, limit: Int = 10) async throws -> [(text: String, similarity: Float)] {
        let queryEmbedding = try await encodeText(query)
        var sentenceResults: [(sentence: EmbeddedSentence, similarity: Float)] = []
        
        for sentence in sentences {
            let similarity = cosineSimilarity(queryEmbedding, sentence.embedding)
            sentenceResults.append((sentence: sentence, similarity: similarity))
        }
        
        sentenceResults.sort { $0.similarity > $1.similarity }
        
        var seenDocuments: Set<String> = []
        var seenParagraphs: Set<String> = []
        var results: [(text: String, similarity: Float)] = []
        
        for sentenceResult in sentenceResults {
            switch unit {
            case .document:
                if seenDocuments.contains(sentenceResult.sentence.documentId) { continue }
                if let documentText = documents[sentenceResult.sentence.documentId]?.text {
                    results.append((documentText, sentenceResult.similarity))
                    seenDocuments.insert(sentenceResult.sentence.documentId)
                }
            case .paragraph:
                if seenParagraphs.contains(sentenceResult.sentence.paragraphId) { continue }
                if let paragraphText = paragraphs[sentenceResult.sentence.paragraphId]?.text {
                    results.append((paragraphText, sentenceResult.similarity))
                    seenParagraphs.insert(sentenceResult.sentence.paragraphId)
                }
            case .sentence:
                results.append((sentenceResult.sentence.text, sentenceResult.similarity))
            }
        }
        
        return results.prefix(limit).map { $0 }
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
