//
//  NewSystemPromptView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import KeyboardShortcuts
import SwiftUI

struct NewSystemPromptView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var savedPrompt: SystemPrompt
    @Binding var isSaved: Bool
    @Binding var shortcutChanged: Bool
    
    @FocusState private var isFocused: Bool
    @State private var appSearchText: String = ""
    @State private var showAppSelector: Bool = false
    
    init(prompt: Binding<SystemPrompt>, isSaved: Binding<Bool>, shortcutChanged: Binding<Bool>) {
        self._savedPrompt = prompt
        self._isSaved = isSaved
        self._shortcutChanged = shortcutChanged
    }
    
    private var allApps: [URL] {
        FileManager.default.installedApps()
            .sorted {
                let left = $0.deletingPathExtension().lastPathComponent.lowercased()
                let right = $1.deletingPathExtension().lastPathComponent.lowercased()
                
                return left < right
            }
            .filter { !savedPrompt.applications.contains($0) }
    }
    
    private var filteredApps: [URL] {
        if appSearchText.isEmpty {
            return allApps
        } else {
            return allApps.filter { url in
                url.deletingPathExtension().lastPathComponent
                    .localizedCaseInsensitiveContains(appSearchText)
            }
        }
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
    
    private var appSelectorPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Applications")
                .font(.headline)
                .foregroundStyle(.gray100)
            
            // Search field
            TextField("Search applications...", text: $appSearchText)
                .textFieldStyle(.plain)
                .padding(8)
                .background(.gray700)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(.gray500)
                )
            
            // Apps list
            VStack {
                if filteredApps.isEmpty {
                    Text("No applications found")
                        .foregroundStyle(.gray200)
                        .padding(.vertical, 8)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(filteredApps, id: \.self) { url in
                                Button(action: {
                                    savedPrompt.applications.append(url)
                                    appSearchText = "" // Clear search after selection
                                    showAppSelector = false // Close popover
                                }) {
                                    HStack {
                                        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                        Text(url.deletingPathExtension().lastPathComponent)
                                            .foregroundStyle(.FG)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(.clear)
                                .cornerRadius(4)
                                .contentShape(Rectangle())
                            }
                        }
                    }
                }
            }
            .frame(minHeight: 200, maxHeight: 300)
        }
        .padding(16)
        .frame(width: 300)
        .background(.gray800)
    }
    
    // MARK: - Views
    
    var body: some View {
        if #available(macOS 15.0, *) {
            content
                .presentationSizing(.fitted)
        } else {
            content
                .frame(height: 570)
        }
    }
    
    var content: some View {
        VStack {
            titleBar
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                            .foregroundStyle(.gray100)
                        TextField("Helpful Assistant", text: $savedPrompt.name)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(.gray700)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.gray500)
                            )
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Prompt*")
                            .font(.headline)
                            .foregroundStyle(.gray100)
                        VStack {
                            TextEditor(text: $savedPrompt.prompt)
                                .textEditorStyle(.plain)
                                .frame(height: 100)
                                .foregroundStyle(promptIsPlaceholder ? .white.opacity(0.3) : .white)
                                .focused($isFocused)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 3)
                        .background(.gray700)
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.gray500)
                        )
                    }
                    KeyboardShortcuts.Recorder(
                        "Hotkey", name: KeyboardShortcuts.Name(savedPrompt.id)
                    ) { shortcut in
                        if isSaved {
                            shortcutChanged.toggle()
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.gray100)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rules for suggestions")
                            .font(.headline)
                            .foregroundStyle(.gray100)
                        Text("Make this system prompt the default suggestion for specific applications and keywords.")
                            .foregroundStyle(.gray200)
                    }
                    applications
                    tags
                    if !isSaved {
                        buttons
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
        .background(.gray800)
        .frame(maxWidth: 400, alignment: .leading)
    }
    
    private var titleBar: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(.smallCross)
                            .frame(width: 48, height: 32)
                            .foregroundStyle(.gray200)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                
                Text("System Prompt")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(.gray200)
            }
            Divider()
        }
    }
    
    private var applications: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Applications")
                .font(.headline)
                .foregroundStyle(.gray100)
            
            HStack {
                Button {
                    showAppSelector = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray100)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showAppSelector) {
                    appSelectorPopover
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        if savedPrompt.applications.isEmpty {
                            Text("No app added")
                                .foregroundColor(.white.opacity(0.3))
                        } else {
                            ForEach(savedPrompt.applications, id: \.self) { url in
                                HStack(spacing: 2) {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                    
                                    Text(url.deletingPathExtension().lastPathComponent)
                                    
                                    Button(action: {
                                        savedPrompt.applications.removeAll { $0 == url }
                                    }) {
                                        Image(.smallCross)
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                            .foregroundColor(.gray)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(4)
                                .background(.gray400)
                                .cornerRadius(3)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 34)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray700)
                        .stroke(.gray500, lineWidth: 1)
                }
            }
        }
    }
    
    private var tags: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
                .foregroundStyle(.gray100)
            TextField("Separate with commas", text: keywordsBinding)
                .textFieldStyle(.plain)
                .padding(8)
                .background(.gray700)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.gray500)
                )
            Text("e.g. frameworks, languages, emails, websites, topics...")
                .foregroundStyle(.gray200)
        }
    }
    
    private var buttons: some View {
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
}

#Preview {
    NewSystemPromptView(prompt: .constant(SystemPrompt()),
                        isSaved: .constant(false),
                        shortcutChanged: .constant(false))
}
