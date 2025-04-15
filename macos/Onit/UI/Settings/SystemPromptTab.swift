//
//  SystemPromptTab.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import Defaults
import SwiftData
import SwiftUI

struct SystemPromptTab: View {
    @Environment(\.modelContext) var modelContext
    @Default(.systemPromptId) var systemPromptId
    
    @State var searchText: String = ""
    @State var selectedPrompt: SystemPrompt? = nil
    @State var shouldDeleteSelectedPrompt: Bool = false
    
    @State var showAdd: Bool = false
    @State var promptToAdd: SystemPrompt = SystemPrompt()
    @State var shouldSavePrompt: Bool = false
    
    @State private var shortcutChanged = false
    
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
                HStack {
                    CustomTextField(
                        text: $searchText,
                        placeholder: "Search name, prompt or tag...",
                        config: CustomTextField.Config(
                            strokeColor: .gray300,
                            hoverStrokeColor: .gray200,
                            focusedStrokeColor: .gray100,
                            clear: true,
                            leftIcon: .search
                        )
                    )
                    
                    Button {
                        showAdd = true
                    } label: {
                        Text("Add new")
                    }
                    .foregroundStyle(.white)
                    .buttonStyle(.borderedProminent)
                    .frame(height: 22)
                    .fontWeight(.regular)

                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                
                HStack {
                    SettingsSystemPromptTable(filter: $searchText,
                                     selectedPrompt: $selectedPrompt,
                                     refreshUI: $shortcutChanged)
                    
                    if selectedPrompt != nil {
                        SettingsSystemPromptDetail(prompt: unwrappedSelectedPrompt,
                                           shouldBeDeleted: $shouldDeleteSelectedPrompt,
                                           shortcutChanged: $shortcutChanged)
                        .frame(width: geometry.size.width * detailsWidthRatio)
                    }
                }
            }
            .onDisappear {
                resetData()
            }
            .onChange(of: shouldDeleteSelectedPrompt) { _, new in
                if new {
                    Task { @MainActor in
                        deleteSelectedPrompt()
                    }
                }
            }
            .onChange(of: shouldSavePrompt) { _, new in
                if new {
                    Task { @MainActor in
                        addPrompt()
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                NewSystemPromptView(prompt: $promptToAdd,
                                    isSaved: $shouldSavePrompt,
                                    shortcutChanged: .constant(false))
            }
        }
    }
    
    private func addPrompt() {
        modelContext.insert(promptToAdd)
        try! modelContext.save()
        
        KeyboardShortcutsManager.register(systemPrompt: promptToAdd)
        
        promptToAdd = SystemPrompt()
        shouldSavePrompt = false
    }
    
    private func deleteSelectedPrompt() {
        if let systemPrompt = selectedPrompt {
            selectedPrompt = nil
            
            /// The prompt we're deleting is the one selected for chat
            if systemPromptId == systemPrompt.id {
                selectMostRecentlyUsedPrompt(deletedId: systemPrompt.id)
            }
            
            // Unregister the shortcut keyboard
            KeyboardShortcutsManager.unregister(systemPrompt: systemPrompt)
            
            modelContext.delete(systemPrompt)
            try! modelContext.save()
        }
        
        shouldDeleteSelectedPrompt = false
    }
    
    private func selectMostRecentlyUsedPrompt(deletedId: String) {
        var fetchDescriptor = FetchDescriptor<SystemPrompt>(
            predicate: #Predicate { $0.id != deletedId },
            sortBy: [SortDescriptor(\.lastUsed, order: .reverse)]
        )
        fetchDescriptor.fetchLimit = 1
        
        do {
            let result = try modelContext.fetch(fetchDescriptor)
            if let systemPrompt = result.first {
                systemPromptId = systemPrompt.id
            } else {
                systemPromptId = SystemPrompt.outputOnly.id
            }
        } catch {
            systemPromptId = SystemPrompt.outputOnly.id
        }
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
