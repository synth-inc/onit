//
//  EmbeddingsTab.swift
//  Onit
//
//  Created by Jason Swanson on 5/12/25.
//

import SwiftUI

struct EmbeddingsTab: View {
    @StateObject private var embeddingsService = EmbeddingsService()
    
    @State private var searchText: String = ""
    @State private var searchResults: [(text: String, similarity: Float)]?
    
    @State private var testData: String = ""
    
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {
            TextField("Search Your Test Data", text: $searchText)
                .onSubmit {
                    handleSearch()
                }
            Button("Search") {
                handleSearch()
            }
            TextField("Input Some Test Data", text: $testData)
                .onSubmit {
                    handleEmbed()
                }
            Button("Embed") {
                handleEmbed()
            }
            Spacer()
            List {
                if let searchResults = searchResults {
                    ForEach(searchResults, id: \.text) { searchResult in
                        VStack(alignment: .leading) {
                            Text(searchResult.text)
                            Text("Similarity: \(searchResult.similarity)")
                        }
                    }
                } else {
                    ForEach(embeddingsService.embeddings, id: \.id) { embedding in
                        VStack(alignment: .leading) {
                            Text(embedding.text)
                            Text("[\(embedding.embeddingString.prefix(60))...")
                        }
                    }
                }
            }
        }
    }
    
    func handleSearch() {
        if searchText.isEmpty {
            return
        }
        
        if #available(macOS 15.0, *) {
            Task {
                do {
                    searchResults = try await embeddingsService.searchSimilarTexts(query: searchText, limit: 10)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func handleEmbed() {
        if testData.isEmpty {
            return
        }
        
        if #available(macOS 15.0, *) {
            let text = testData
            testData = ""
            Task {
                do {
                    try await embeddingsService.storeText(text)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } else {
            errorMessage = "This feature is not supported for your platform."
        }
    }
}
