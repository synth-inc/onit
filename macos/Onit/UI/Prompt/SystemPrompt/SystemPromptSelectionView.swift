//
//  SystemPromptSelectionView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import SwiftData
import SwiftUI

struct SystemPromptSelectionView: View {
    @Environment(\.appState) private var appState
    @Environment(\.openSettings) private var openSettings
    @Environment(\.windowState) private var state
    
    @Query(sort: \SystemPrompt.timestamp, order: .reverse) var prompts: [SystemPrompt]
    
    @Binding var showNewPrompt: Bool
    @State private var searchText = ""
    
    init(showNewPrompt: Binding<Bool>) {
        self._showNewPrompt = showNewPrompt
    }
    
    private var suggestedPrompts: [SystemPrompt] {
        state?.promptSuggestionService?.suggestedPrompts ?? []
    }
    
    private var allPrompts: [SystemPrompt] {
        prompts.filter { prompt in
            !suggestedPrompts.contains { $0.id == prompt.id }
        }
    }
    
    private var clearFilter: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private var filteredPrompts: [SystemPrompt] {
        guard !clearFilter.isEmpty else { return prompts }
        
        return prompts.filter { prompt in
            prompt.name.lowercased().contains(clearFilter) ||
            prompt.prompt.lowercased().contains(clearFilter) ||
            prompt.applications.contains { url in
                url.deletingPathExtension().lastPathComponent
                   .lowercased().contains(clearFilter)
            } ||
            prompt.tags.joined(separator: ",").lowercased().contains(clearFilter)
        }
    }
    
    var body: some View {
        MenuList(
            header: MenuHeader(title: "System Prompts") {
                IconButton(
                    icon: .cross,
                    iconSize: 10
                ) {
                    state?.systemPromptState.shouldShowSelection = false
                }
            },
            search: MenuList.Search(
                query: $searchText,
                placeholder: "Search by prompts, apps, or tags..."
            )
        ) {
            promptsList
            buttons
        }
    }
    
    var promptsList: some View {
        MenuSection(showTopBorder: true) {
            ScrollViewReader { proxy in
                List() {
                    EmptyView().id("topScrollPoint")
                    
                    if !suggestedPrompts.isEmpty && searchText.isEmpty {
                        sectionView(title: "Suggested", prompts: suggestedPrompts)
                        sectionView(title: "All", prompts: allPrompts)
                    } else {
                        sectionView(title: nil, prompts: filteredPrompts)
                    }
                }
                .frame(height: 244)
                .padding(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8))
                .clipShape(Rectangle())
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .onChange(of: filteredPrompts) { _, _ in
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(100))
                        withAnimation(.smooth(duration: 0.3)) {
                            proxy.scrollTo("topScrollPoint")
                        }
                    }
                }
            }
        }
    }
    
    private func sectionView(title: String?, prompts: [SystemPrompt]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = title {
                Text(title).foregroundStyle(.gray200)
            }
            
            ForEach(prompts, id: \.id) { prompt in
                SystemPromptSelectionRowView(prompt: prompt)
            }
        }
        .listRowSeparator(.hidden)
    }
    
    private var buttons: some View {
        MenuSection(showTopBorder: true) {
            HStack(alignment: .center, spacing: 8) {
                Button {
                    appState.setSettingsTab(tab: .prompts)
                    openSettings()
                } label: {
                    Label("Settings", systemImage: "message")
                        .foregroundStyle(.gray100)
                        .font(.system(size: 13))
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button {
                    showNewPrompt = true
                } label: {
                    Label("New Prompt", image: .plus)
                        .foregroundStyle(.gray100)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    SystemPromptSelectionView(showNewPrompt: .constant(false))
}
