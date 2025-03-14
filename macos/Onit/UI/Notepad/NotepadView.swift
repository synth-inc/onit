//
//  NotepadView.swift
//  Onit
//
//  Created by Kévin Naudin on 13/03/2025.
//

import SwiftUI

struct NotepadView: View {
    let closeCompletion: (() -> Void)
    
    @EnvironmentObject var config: NotepadConfig
    
    init(closeCompletion: @escaping () -> Void) {
        self.closeCompletion = closeCompletion
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            PromptDivider()
            DiffView(oldText: $config.oldText, newText: $config.newText, isStreaming: $config.isStreaming)
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
    NotepadView {
        
    }
    .environmentObject(NotepadConfig())
}
