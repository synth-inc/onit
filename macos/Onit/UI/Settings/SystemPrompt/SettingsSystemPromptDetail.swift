//
//  SettingsSystemPromptDetail.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import KeyboardShortcuts
import SwiftUI

struct SettingsSystemPromptDetail: View {
    @Binding var prompt: SystemPrompt
    @Binding var shouldBeDeleted: Bool
    @Binding var shortcutChanged: Bool
    
    @State private var showEdit = false
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 20) {
                Text(prompt.name)
                    .font(.title3)
                    .bold()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt")
                        .bold()
                    Text(prompt.prompt)
                }
                if let shortcut = KeyboardShortcuts.Name(prompt.id).shortcut?.native {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hotkey")
                            .bold()
                        KeyboardShortcutView(shortcut: shortcut, characterWidth: 12, spacing: 3)
                            .font(.system(size: 13, weight: .light))
                    }
                }
                if !prompt.applications.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Applications")
                            .bold()
                        FlowLayout(spacing: 8) {
                            ForEach(prompt.applications, id: \.self) { url in
                                HStack(alignment: .center, spacing: 4) {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                    Text(url.deletingPathExtension().lastPathComponent)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(.gray300)
                                }
                            }
                        }
                    }
                }
                if !prompt.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .bold()
                        
                        FlowLayout(spacing: 8) {
                            ForEach(prompt.tags, id: \.self) { tag in
                                Text(tag)
                                    .lineLimit(1)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background {
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(.gray300)
                                    }
                            }
                        }
                    }
                }
                
                Spacer()
                
                if prompt.id != SystemPrompt.outputOnly.id {
                    buttons
                }
            }
            .padding()
            .sheet(isPresented: $showEdit) {
                NewSystemPromptView(prompt: $prompt, isSaved: .constant(true), shortcutChanged: $shortcutChanged)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
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

#if DEBUG
    #Preview {
        SettingsSystemPromptDetail(prompt: .constant(PreviewSampleData.systemPrompt),
                           shouldBeDeleted: .constant(false),
                           shortcutChanged: .constant(false))
    }
#endif
