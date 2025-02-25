//
//  SystemPromptDetailView.swift
//  Onit
//
//  Created by Kévin Naudin on 10/02/2025.
//

import Defaults
import KeyboardShortcuts
import SwiftUI
import SwiftData

struct SystemPromptDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Default(.systemPromptId) private var systemPromptId
    
    @Binding var size: CGSize
    @Binding var showSelection: Bool
    @Binding var showEditPrompt: Bool

    @State private var storedPrompt: SystemPrompt = .outputOnly
        
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Prompt")
                    .foregroundStyle(.gray100)
                    .bold()
                Text(storedPrompt.prompt)
            }
            
            if let shortcut = KeyboardShortcuts.Name(storedPrompt.id).shortcut?.native {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hotkey")
                        .foregroundStyle(.gray100)
                        .bold()
                    KeyboardShortcutView(shortcut: shortcut, characterWidth: 12, spacing: 3)
                        .font(.system(size: 13, weight: .light))
                }
            }
            
            if !storedPrompt.applications.isEmpty || !storedPrompt.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apps & Tags")
                        .foregroundStyle(.gray100)
                        .bold()
                    appsAndTags
                }
            }

            buttons
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.gray800)
                .strokeBorder(.gray600)
        }
        .frame(width: size.width - 16)
        .onChange(of: systemPromptId, initial: true) { oldValue, newValue in
            let descriptor = FetchDescriptor<SystemPrompt>()
            
            guard let prompt = try? modelContext.fetch(descriptor).first(where: { $0.id == newValue }) else {
                storedPrompt = .outputOnly
                print("Could not find prompt")
                return
            }
            
            storedPrompt = prompt
        }
    }
    
    private var appsAndTags: some View {
        FlowLayout(spacing: 8) {
            ForEach(storedPrompt.applications, id: \.self) { url in
                HStack(alignment: .center, spacing: 4) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text(url.deletingPathExtension().lastPathComponent)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(.gray500)
                }
            }
            
            ForEach(storedPrompt.tags, id: \.self) { tag in
                Text(tag)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
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
                }.tooltip(prompt: "Edit")
            }
        }
    }
}

#Preview {
    let size: Binding<CGSize> = .constant(.init(width: 200, height: 40))
    
    SystemPromptDetailView(size: size, showSelection: .constant(false), showEditPrompt: .constant(false))
}
