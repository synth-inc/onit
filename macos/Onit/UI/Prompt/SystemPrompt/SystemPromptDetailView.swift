//
//  SystemPromptDetailView.swift
//  Onit
//
//  Created by Kévin Naudin on 10/02/2025.
//

import Defaults
import SwiftUI
import SwiftData

struct SystemPromptDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Default(.systemPromptId) private var systemPromptId
    
    @Binding var size: CGSize
    @Binding var showSelection: Bool
    @Binding var showEditPrompt: Bool

    var storedPrompt: SystemPrompt {
        guard let prompt = try? modelContext.fetch(FetchDescriptor<SystemPrompt>()).first(where: { $0.id == systemPromptId }) else {
            fatalError("Could not find prompt")
        }
        
        return prompt
    }
    
    private let layout = [GridItem(.adaptive(minimum: 100), spacing: 10)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prompt")
                .foregroundStyle(.gray100)
                .bold()
            Text(storedPrompt.prompt)

            if !storedPrompt.applications.isEmpty || !storedPrompt.tags.isEmpty {
                Text("Apps & Tags")
                    .foregroundStyle(.gray100)
                    .bold()
                appsAndTags
            }

            buttons
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.gray800)
                .strokeBorder(.gray600)
        }
        .frame(width: size.width - 16)
    }
    
    private var appsAndTags: some View {
        LazyVGrid(columns: layout, alignment: .leading, spacing: 10) {
            ForEach(storedPrompt.applications, id: \.self) { url in
                HStack(alignment: .center, spacing: 4) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text(url.deletingPathExtension().lastPathComponent)
                }
                .padding(2)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.gray500)
                }
            }
            
            ForEach(storedPrompt.tags, id: \.self) { tag in
                HStack(alignment: .center) {
                    Text(tag)
                        .padding(2)
                }
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.gray500)
                }
            }
        }
    }
    
    private var buttons: some View {
        HStack(alignment: .center) {
            Button {
                showSelection = true
                dismiss()
            } label: {
                Text("Select another prompt")
                    .foregroundStyle(.gray100)
                    .underline()
            }.buttonStyle(.plain)
            
            Spacer()
            
            if systemPromptId != SystemPrompt.outputOnly.id {
                Button {
                    showEditPrompt = true
                    dismiss()
                } label: {
                    Image(.pencil)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.gray100)
                }.buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    let size: Binding<CGSize> = .constant(.init(width: 200, height: 40))
    
    SystemPromptDetailView(size: size, showSelection: .constant(false), showEditPrompt: .constant(false))
}
