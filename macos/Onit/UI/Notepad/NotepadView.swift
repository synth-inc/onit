//
//  NotepadView.swift
//  Onit
//
//  Created by Kévin Naudin on 13/03/2025.
//

import SwiftUI
import SwiftData

struct NotepadView: View {
    let response: Response
    let closeCompletion: (() -> Void)
    
    @Environment(\.modelContext) private var modelContext
    
    init(response: Response, closeCompletion: @escaping () -> Void) {
        self.response = response
        self.closeCompletion = closeCompletion
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            PromptDivider()
            DiffView(response: response, modelContext: modelContext)
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
