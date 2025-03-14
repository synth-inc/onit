//
//  NotepadView.swift
//  Onit
//
//  Created by Kévin Naudin on 13/03/2025.
//

import SwiftUI

struct NotepadView: View {
    @Environment(\.model) private var model
    
    let closeCompletion: (() -> Void)
    
    @Binding var prompt: Prompt?
    
    init(prompt: Binding<Prompt?> = .constant(nil), closeCompletion: @escaping () -> Void) {
        self._prompt = prompt
        self.closeCompletion = closeCompletion
    }
    
    private var oldText: String {
        guard let prompt = prompt else { return "" }
        
        let autoContexts = prompt.contextList.autoContexts
        
        if let input = prompt.input {
            print("NotepadView oldText : \(input.selectedText)")
            return input.selectedText
        } else if !autoContexts.isEmpty {
            print("NotepadView oldText : \(autoContexts.values.joined(separator: "\n"))")
            return autoContexts.values.joined(separator: "\n")
        }
        
        return ""
    }
    private var newText: String {
        guard let prompt = prompt else { return "" }
        
        let response = prompt.responses[prompt.generationIndex]
        
        print("NotepadView newText : \(response.isPartial ? model.streamedResponse : response.text)")
        
        return response.isPartial ? model.streamedResponse : response.text
    }
    private var isStreaming: Bool {
        guard let prompt = prompt else {
            return false
        }
        
        let response = prompt.responses[prompt.generationIndex]
        
        print("NotepadView isStreaming : \(response.isPartial)")
        
        return response.isPartial
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            PromptDivider()
            DiffView(oldText: oldText, newText: newText, isStreaming: isStreaming)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    private var toolbar: some View {
        HStack {
            close
            Spacer()
            
        }
        .frame(height: 32)
    }
    
    private var close: some View {
        Button(action: closeCompletion) {
            Image(.smallCross)
                .frame(width: 48, height: 32)
                .foregroundStyle(.gray200)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NotepadView(prompt: .constant(nil)) {
        
    }
}
