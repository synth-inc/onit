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
            HStack {
                Button("Search Documents") {
                    handleSearch(.document)
                }
                Button("Search Paragraphs") {
                    handleSearch(.paragraph)
                }
                Button("Search Sentences") {
                    handleSearch(.sentence)
                }
            }

            TextField("Input Some Test Data", text: $testData)
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
                    ForEach(embeddingsService.sentences, id: \.id) { embedding in
                        VStack(alignment: .leading) {
                            Text(embedding.text)
                            Text("[\(embedding.embeddingString.prefix(60))...")
                        }
                    }
                }
            }
        }
    }
    
    func handleSearch(_ unit: EmbeddingsService.Unit) {
        if searchText.isEmpty {
            return
        }
        
        if #available(macOS 15.0, *) {
            Task {
                do {
                    searchResults = try await embeddingsService.searchSimilarTexts(query: searchText, unit: unit, limit: 10)
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
        
        searchResults = nil
        
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
