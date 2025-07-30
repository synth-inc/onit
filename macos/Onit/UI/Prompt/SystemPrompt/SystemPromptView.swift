//
//  SystemPromptView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import Defaults
import SwiftData
import SwiftUI

struct SystemPromptView: View {
    @Environment(\.windowState) var windowState
    @Environment(\.modelContext) var modelContext
    
    @State private var showSelection: Bool = false
    @State private var showDetail: Bool = false
    @State private var showNewPrompt: Bool = false
    @State private var showEditPrompt: Bool = false
    @State var promptToAdd: SystemPrompt = SystemPrompt()
    @State var shouldSavePrompt: Bool = false
    
    @State var size: CGSize = .zero
    @State var selectedPrompt: SystemPrompt = .outputOnly
    
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    private var editPromptBinding: Binding<SystemPrompt> {
        Binding {
            selectedPrompt
        } set: { _ in }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(.chatSettings)
                .resizable()
                .frame(width: 14, height: 14)
                .allowsHitTesting(false)
            
            Text(selectedPrompt.name)
                .lineLimit(1)
                .allowsHitTesting(false)
            
            Spacer()
            
            Button {
                showDetail = true
            } label: {
                Image(systemName: "info.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
            }
            
            Spacer()
                .frame(width: 4)
            
            Button {
                windowState?.systemPromptState.shouldShowSystemPrompt = false
            } label: {
                Image(.remove)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
            }
        }
        .popover(isPresented: .init(
            get: { showSelection || windowState?.systemPromptState.shouldShowSelection == true },
            set: {
                showSelection = $0
                windowState?.systemPromptState.shouldShowSelection = $0
            }
        ), arrowEdge: .leading) {
            SystemPromptSelectionView(showNewPrompt: $showNewPrompt)
        }
        .popover(isPresented: $showDetail, arrowEdge: .bottom) {
            SystemPromptDetailView(size: $size, showSelection: $showSelection, showEditPrompt: $showEditPrompt)
        }
        .sheet(isPresented: $showNewPrompt) {
            NewSystemPromptView(prompt: $promptToAdd, isSaved: $shouldSavePrompt, shortcutChanged: .constant(false))
        }
        .sheet(isPresented: $showEditPrompt) {
            NewSystemPromptView(prompt: editPromptBinding, isSaved: .constant(true), shortcutChanged: .constant(false))
        }
        .onChange(of: shouldSavePrompt) { _, new in
            if new { addPrompt() }
        }
        .onChange(of: windowState?.systemPromptId, initial: true) { _, systemPromptId in
            guard let prompts = try? modelContext.fetch(FetchDescriptor<SystemPrompt>()),
                  let prompt = prompts.first(where: { $0.id == systemPromptId }) else {
                selectedPrompt = .outputOnly
                errorMessage = "Could not find the selected prompt. Using default prompt instead."
                showErrorAlert = true
                return
            }
            
            selectedPrompt = prompt
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.messageBG)
                .strokeBorder(Color.genericBorder)
                .onTapGesture {
                    showSelection = true
                }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .saveSize(in: $size)
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func addPrompt() {
        modelContext.insert(promptToAdd)
        do {
            try modelContext.save()
            KeyboardShortcutsManager.register(systemPrompt: promptToAdd)
            windowState?.systemPromptId = promptToAdd.id
            promptToAdd = SystemPrompt()
            shouldSavePrompt = false
        } catch {
            errorMessage = "Unable to save the prompt: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

#Preview {
    SystemPromptView()
}
