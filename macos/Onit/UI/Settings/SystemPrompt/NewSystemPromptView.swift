//
//  NewSystemPromptView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import SwiftUI

struct NewSystemPromptView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var savedPrompt: SystemPrompt
    @Binding var isSaved: Bool
    
    @FocusState private var isFocused: Bool
    
    init(prompt: Binding<SystemPrompt>, isSaved: Binding<Bool>) {
        self._savedPrompt = prompt
        self._isSaved = isSaved
    }
    
    private var allApps: [URL] {
        FileManager.default.installedApps().filter { !savedPrompt.applications.contains($0) }
    }
    
    static private let promptPlaceholder = "Enter instructions to define role, tone and boundaries of the AI"
    
    private var promptIsPlaceholder: Bool {
        return savedPrompt.prompt == Self.promptPlaceholder
    }
    
    private var keywordsBinding: Binding<String> {
        .init(
            get: { self.savedPrompt.tags.joined(separator: ", ") },
            set: { newValue in
                self.savedPrompt.tags = newValue.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
        )
    }
    
    private var saveButtonDisabled: Bool {
        savedPrompt.name.isEmpty || promptIsPlaceholder || savedPrompt.prompt.isEmpty
    }
    
    var body: some View {
        titleBar
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.headline)
                    TextField("Helpful Assistant", text: $savedPrompt.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Prompt*")
                        .font(.headline)
                    VStack {
                        TextEditor(text: $savedPrompt.prompt)
                            .textEditorStyle(.plain)
                            .frame(height: 100)
                            .foregroundStyle(promptIsPlaceholder ? .gray : .white)
                            .focused($isFocused)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray500, lineWidth: 1)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rules for suggestions")
                        .font(.headline)
                    Text("Make this system prompt the default suggestion for specific applications and keywords.")
                }
                
                applications
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    TextField("Separate with commas", text: keywordsBinding)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("e.g. frameworks, languages, emails, websites, topics...")
                }
                if !isSaved {
                    HStack {
                        Spacer()
                        Button(action: {
                            isSaved = true
                            dismiss()
                        }) {
                            Text("Save")
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(saveButtonDisabled)
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onChange(of: isFocused, { _, new in
            if new && promptIsPlaceholder {
                self.savedPrompt.prompt = ""
            }
        })
    }
    
    var titleBar: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(.smallCross)
                            .frame(width: 20, height: 20)
                    }
                    .frame(width: 56, height: 32)
                    .buttonStyle(.plain)
                    Spacer()
                }
                
                Text("System Prompt")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            Divider()
        }
    }
    
    var applications: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Applications")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(savedPrompt.applications, id: \.self) { appURL in
                        HStack {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                                .resizable()
                                .frame(width: 15, height: 15)
                            
                            Text(appURL.deletingPathExtension().lastPathComponent)
                                .foregroundColor(.white)
                            Button(action: {
                                savedPrompt.applications.removeAll { $0 == appURL }
                            }) {
                                Image(.smallCross)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(8)
                    }
                }
            }
            
            Menu {
                ForEach(allApps, id: \.self) { url in
                    Button(action: {
                        if !savedPrompt.applications.contains(url) {
                            savedPrompt.applications.append(url)
                        }
                    }) {
                        HStack {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                            Text(url.deletingPathExtension().lastPathComponent)
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Select apps")
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    NewSystemPromptView(prompt: .constant(SystemPrompt()), isSaved: .constant(true))
}
