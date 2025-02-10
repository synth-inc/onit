//
//  SystemPromptDetail.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import SwiftUI

struct SystemPromptDetail: View {
    @Binding var prompt: SystemPrompt
    @Binding var shouldBeDeleted: Bool
    
    @State private var showEdit = false
    
    private let layout = [GridItem(.adaptive(minimum: 60), spacing: 10)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(prompt.name)
                .font(.title3)
                .bold()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Prompt")
                    .bold()
                Text(prompt.prompt)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Applications")
                    .bold()
                LazyVGrid(columns: layout, alignment: .leading, spacing: 10) {
                    ForEach(prompt.applications, id: \.self) { url in
                        HStack(alignment: .center) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                .resizable()
                                .frame(width: 16, height: 16)
                            Text(url.deletingPathExtension().lastPathComponent)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .bold()
                Text(prompt.tags.joined(separator: ","))
            }
            
            Spacer()
            
            if prompt.id != SystemPrompt.outputOnly.id {
                buttons
            }
        }
        .padding()
        .sheet(isPresented: $showEdit) {
            NewSystemPromptView(prompt: $prompt, isSaved: .constant(true))
        }
    }
    
    var buttons: some View {
        HStack {
            Spacer()
            
            Button {
                shouldBeDeleted = true
            } label: {
                Text("Delete")
            }
            
            Button {
                showEdit = true
            } label: {
                Text("Edit")
            }
        }
    }
}

#Preview {
    SystemPromptDetail(prompt: .constant(PreviewSampleData.systemPrompt),
                       shouldBeDeleted: .constant(false))
}
