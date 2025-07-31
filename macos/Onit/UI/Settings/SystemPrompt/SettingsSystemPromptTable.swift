//
//  SettingsSystemPromptTable.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import KeyboardShortcuts
import SwiftData
import SwiftUI

struct SettingsSystemPromptTable: View {
    @Query(sort: \SystemPrompt.timestamp, order: .reverse) var prompts: [SystemPrompt]
    @Binding var filter: String
    @Binding var selectedPrompt: SystemPrompt?
    @Binding var refreshUI: Bool
    
    @State private var selected = Set<SystemPrompt.ID>()
    
    private var clearFilter: String {
        filter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private var filteredPrompts: [SystemPrompt] {
        if clearFilter.isEmpty {
            return prompts
        }
        return prompts.filter { prompt in
            prompt.name.lowercased().contains(clearFilter) ||
            prompt.prompt.lowercased().contains(clearFilter) ||
            prompt.tags.joined(separator: ",").lowercased().contains(clearFilter)
        }
    }
    
    var body: some View {
        Table(filteredPrompts, selection: $selected) {
            TableColumn("Name", value: \.name)
            TableColumn("Hotkey") { prompt in
                if let shortcut = KeyboardShortcuts.Name(prompt.id).shortcut?.native {
                    KeyboardShortcutView(shortcut: shortcut, characterWidth: 12, spacing: 3)
                        .font(.system(size: 13, weight: .light))
                } else {
                    Text("record").foregroundColor(Color.gray)
                }
            }
            TableColumn("Applications") { prompt in
                switch prompt.applications.count {
                case 0:
                    Text("Add default").foregroundColor(Color.gray)
                case 1:
                    Text(prompt.applications.first?.deletingPathExtension().lastPathComponent ?? "")
                default:
                    Text("\(prompt.applications.count)")
                }
            }
            TableColumn("Tags") { prompt in
                Text("\(prompt.tags.count)")
            }
        }
        .id(refreshUI)
        .onChange(of: selected) { _, new in
            Task { @MainActor in
                if let promptId = new.first {
                    selectedPrompt = prompts.first(where: { $0.id == promptId })
                } else {
                    selectedPrompt = nil
                }
            }
        }
        .onChange(of: filter) { _, _ in
            Task { @MainActor in
                selected.removeAll()
                selectedPrompt = nil
            }
        }
    }
}

#Preview {
    SettingsSystemPromptTable(filter: .constant(""),
                     selectedPrompt: .constant(nil),
                     refreshUI: .constant(false))
}
