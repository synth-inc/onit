//
//  SystemPromptTab.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import SwiftData
import SwiftUI

struct SystemPromptTab: View {
    @Environment(\.modelContext) var modelContext
    
    @State var searchText: String = ""
    @State var selectedPrompt: SystemPrompt? = nil
    @State var shouldDeleteSelectedPrompt: Bool = false
    
    @State var showAdd: Bool = false
    @State var promptToAdd: SystemPrompt = SystemPrompt()
    @State var shouldSavePrompt: Bool = false
    
    private let detailsWidthRatio: CGFloat = 0.40
    
    private var unwrappedSelectedPrompt: Binding<SystemPrompt> {
        Binding {
            selectedPrompt ?? SystemPrompt()
        } set: {
            selectedPrompt = $0
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                topView
                HStack {
                    SystemPromptList(filter: $searchText, selectedPrompt: $selectedPrompt)
                    
                    if selectedPrompt != nil {
                        SystemPromptDetail(prompt: unwrappedSelectedPrompt,
                                           shouldBeDeleted: $shouldDeleteSelectedPrompt)
                        .frame(width: geometry.size.width * detailsWidthRatio)
                    }
                }
            }
            .onDisappear {
                resetData()
            }
            .onChange(of: shouldDeleteSelectedPrompt) { _, new in
                if new { deleteSelectedPrompt() }
            }
            .onChange(of: shouldSavePrompt) { _, new in
                if new { addPrompt() }
            }
            .sheet(isPresented: $showAdd) {
                NewSystemPromptView(prompt: $promptToAdd, isSaved: $shouldSavePrompt)
            }
        }
    }
    
    var topView: some View {
        HStack {
            let config = CustomTextField.Config(clear: true, leftIcon: .search)
            
            CustomTextField("Search name, prompt or tag...", text: $searchText, config: config)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button {
                showAdd = true
            } label: {
                Text("Add")
            }

        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
    
    private func addPrompt() {
        modelContext.insert(promptToAdd)
        try! modelContext.save()
        
        promptToAdd = SystemPrompt()
        shouldSavePrompt = false
    }
    
    private func deleteSelectedPrompt() {
        if let model = selectedPrompt {
            selectedPrompt = nil
            do {
                modelContext.delete(model)
                try modelContext.save()
            } catch {
                print("Error occured \(error)")
            }
        }
        
        shouldDeleteSelectedPrompt = false
    }
    
    private func resetData() {
        selectedPrompt = nil
        searchText = ""
        shouldDeleteSelectedPrompt = false
        showAdd = false
        promptToAdd = SystemPrompt()
        shouldSavePrompt = false
    }
}

#Preview {
    SystemPromptTab()
}
