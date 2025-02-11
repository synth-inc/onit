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
    @Environment(\.modelContext) var modelContext
    @Default(.systemPromptId) private var systemPromptId
    @State private var showSelection: Bool = false
    @State private var showDetail: Bool = false
    @State private var showNewPrompt: Bool = false
    @State private var showEditPrompt: Bool = false
    @State var promptToAdd: SystemPrompt = SystemPrompt()
    @State var shouldSavePrompt: Bool = false
    
    @State var size: CGSize = .zero
    
    var selectedPrompt: SystemPrompt {
        guard let prompt = try? modelContext.fetch(FetchDescriptor<SystemPrompt>()).first(where: { $0.id == systemPromptId }) else {
            fatalError("Could not find prompt")
        }
        
        return prompt
    }
    
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
            .buttonStyle(.plain)
        }
        .popover(isPresented: $showSelection, arrowEdge: .leading) {
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
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray800)
                .strokeBorder(.gray600)
                .onTapGesture {
                    showSelection = true
                }
        }
        .padding([.horizontal, .top], 8)
        .saveSize(in: $size)
    }
    
    private func addPrompt() {
        modelContext.insert(promptToAdd)
        try! modelContext.save()
        
        KeyboardShortcutsManager.register(systemPrompt: promptToAdd)
        
        systemPromptId = promptToAdd.id
        
        promptToAdd = SystemPrompt()
        shouldSavePrompt = false
    }
}

#Preview {
    SystemPromptView()
}
