//
//  SettingsSidekickPrompts.swift
//  Onit
//
//  Created by Kévin Naudin on 12/04/2025.
//

import Defaults
import SwiftData
import SwiftUI

struct SettingsSidekickPrompts: View {
    // MARK: - Environment

    @Environment(\.modelContext) var modelContext

    // MARK: - States

    @State private var searchText: String = ""
    @State private var selectedPrompt: SystemPrompt? = nil
    @State private var shouldDeleteSelectedPrompt: Bool = false

    @State private var showAdd: Bool = false
    @State private var promptToAdd: SystemPrompt = SystemPrompt()
    @State private var shouldSavePrompt: Bool = false

    @State private var shortcutChanged = false

    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    // MARK: - Private Properties

    private let detailsWidthRatio: CGFloat = 0.40

    private var unwrappedSelectedPrompt: Binding<SystemPrompt> {
        Binding {
            selectedPrompt ?? SystemPrompt()
        } set: {
            selectedPrompt = $0
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                searchAndAddBar

                HStack(spacing: 0) {
                    SettingsSystemPromptTable(
                        filter: $searchText,
                        selectedPrompt: $selectedPrompt,
                        refreshUI: $shortcutChanged
                    )

                    if selectedPrompt != nil {
                        SettingsSystemPromptDetail(
                            prompt: unwrappedSelectedPrompt,
                            shouldBeDeleted: $shouldDeleteSelectedPrompt,
                            shortcutChanged: $shortcutChanged
                        )
                        .frame(width: geometry.size.width * detailsWidthRatio)
                    }
                }
            }
            .onDisappear {
                resetData()
            }
            .onChange(of: shouldDeleteSelectedPrompt) { _, new in
                if new {
                    deleteSelectedPrompt()
                }
            }
            .onChange(of: shouldSavePrompt) { _, new in
                if new {
                    addPrompt()
                }
            }
            .sheet(isPresented: $showAdd) {
                NewSystemPromptView(
                    prompt: $promptToAdd,
                    isSaved: $shouldSavePrompt,
                    shortcutChanged: .constant(false)
                )
            }
            .alert(String.localized("Error", table: "Settings"), isPresented: $showErrorAlert) {
                Button(String.localized("OK", table: "Settings")) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Child Components

    private var searchAndAddBar: some View {
        HStack(spacing: 8) {
            SearchBar(
                searchQuery: $searchText,
                placeholder: String.localized("Search name, prompt or tag...", table: "Settings"),
                config: SearchBar.config(
                    background: Color.T_9
                )
            )

            TextButton(
                text: String.localized("Add new", table: "Settings"),
                colorConfig: .init(
                    text: Color.white,
                    background: Color.blue
                ),
                sizeConfig: .init(
                    text: 13,
                    horizontalPadding: 16,
                    height: 32
                )
            ) {
                showAdd = true
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Private Functions

    private func addPrompt() {
        modelContext.insert(promptToAdd)
        do {
            try modelContext.save()
            KeyboardShortcutsManager.register(systemPrompt: promptToAdd)
            promptToAdd = SystemPrompt()
            shouldSavePrompt = false
        } catch {
            errorMessage = String(format: String.localized("Unable to save the prompt: %@", table: "Settings"), error.localizedDescription)
            showErrorAlert = true
        }
    }

    private func deleteSelectedPrompt() {
        if let systemPrompt = selectedPrompt {
            selectedPrompt = nil

            selectMostRecentlyUsedPromptIfNeeded(deletedId: systemPrompt.id)

            KeyboardShortcutsManager.unregister(systemPrompt: systemPrompt)

            modelContext.delete(systemPrompt)
            do {
                try modelContext.save()
            } catch {
                errorMessage = String(format: String.localized("Unable to delete the prompt: %@", table: "Settings"), error.localizedDescription)
                showErrorAlert = true
            }
        }

        shouldDeleteSelectedPrompt = false
    }

    private func selectMostRecentlyUsedPromptIfNeeded(deletedId: String) {
        var fetchDescriptor = FetchDescriptor<SystemPrompt>(
            predicate: #Predicate { $0.id != deletedId },
            sortBy: [SortDescriptor(\.lastUsed, order: .reverse)]
        )
        fetchDescriptor.fetchLimit = 1

        for state in PanelStateCoordinator.shared.states {
            if state.systemPromptId == deletedId {
                do {
                    let result = try modelContext.fetch(fetchDescriptor)

                    if let systemPrompt = result.first {
                        state.systemPromptId = systemPrompt.id
                    } else {
                        state.systemPromptId = SystemPrompt.outputOnly.id
                    }
                } catch {
                    print("Failed to fetch replacement prompt: \(error)")
                    state.systemPromptId = SystemPrompt.outputOnly.id
                }
            }
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
