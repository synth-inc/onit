//
//  AddMemorySheet.swift
//  Onit
//
//  Created by Kévin Naudin on 22/12/2025.
//

import SwiftUI

/// Sheet modal for creating a new memory
struct AddMemorySheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Bindings

    @Binding var content: String

    // MARK: - States

    @State private var isGlobal: Bool = true
    @State private var selectedAppURL: URL? = nil
    @State private var showAppSelector: Bool = false
    @State private var appSearchText: String = ""

    // MARK: - Properties

    let onSave: (Memory) -> Void

    // MARK: - Computed Properties

    private var isContentValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var allApps: [URL] {
        FileManager.default.installedApps()
            .sorted {
                let left = $0.deletingPathExtension().lastPathComponent.lowercased()
                let right = $1.deletingPathExtension().lastPathComponent.lowercased()
                return left < right
            }
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

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            textEditor

            scopeSelector

            actionButtons
        }
        .padding(16)
        .frame(width: 300)
        .background(Color.S_7)
    }

    // MARK: - Child Components

    private var header: some View {
        Text("Add Memory")
            .styleText(size: 14, weight: .semibold)
    }

    private var textEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextEditor(text: $content)
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(height: 80)
                .background(Color.T_8)
                .cornerRadius(6)
                .addBorder(cornerRadius: 6, stroke: Color.T_6)

            Text("e.g., I prefer Swift over Objective-C")
                .styleText(size: 10, color: Color.T_4)
        }
    }

    private var scopeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Apply to")
                .styleText(size: 12, weight: .medium)

            VStack(spacing: 0) {
                ScopeSelectionButton(
                    text: "All apps",
                    icon: "globe",
                    selected: isGlobal
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isGlobal = true
                        selectedAppURL = nil
                    }
                }

                ScopeSelectionButton(
                    text: "Specific app",
                    icon: "app.badge",
                    selected: !isGlobal
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isGlobal = false
                    }
                }
            }
            .background(Color.T_8.opacity(0.5))
            .cornerRadius(6)
            .addBorder(cornerRadius: 6, stroke: Color.T_6)

            if !isGlobal {
                appSelector
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var appSelector: some View {
        HStack(spacing: 8) {
            Button {
                showAppSelector = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.T_3)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showAppSelector) {
                appSelectorPopover
            }

            if let appURL = selectedAppURL {
                HStack(spacing: 4) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                        .resizable()
                        .frame(width: 14, height: 14)

                    Text(appURL.deletingPathExtension().lastPathComponent)
                        .styleText(size: 11)

                    Button {
                        selectedAppURL = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color.T_3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.T_7)
                .cornerRadius(4)
            } else {
                Text("No app selected")
                    .styleText(size: 11, color: Color.T_4)
            }

            Spacer()
        }
        .padding(8)
        .background(Color.T_8.opacity(0.5))
        .cornerRadius(6)
        .addBorder(cornerRadius: 6, stroke: Color.T_6)
    }

    private var appSelectorPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Application")
                .styleText(size: 13, weight: .semibold)

            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(Color.T_4)

                TextField("Search...", text: $appSearchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(8)
            .background(Color.T_8)
            .cornerRadius(6)
            .addBorder(cornerRadius: 6, stroke: Color.T_6)

            // Apps list
            ScrollView {
                LazyVStack(spacing: 2) {
                    if filteredApps.isEmpty {
                        Text("No applications found")
                            .styleText(size: 11, color: Color.T_4)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(filteredApps, id: \.self) { url in
                            AppRow(url: url) {
                                selectedAppURL = url
                                appSearchText = ""
                                showAppSelector = false
                            }
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding(12)
        .frame(width: 250)
        .background(Color.S_7)
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            TextButton (
                text: String.localized("Cancel", table: "Settings"),
                colorConfig: .init(
                    background: Color.T_7
                ),
                sizeConfig: .init(
                    height: 32,
                    cornerRadius: 6
                ),
                statusConfig: .init(
                    fillContainer: true
                )
            ) {
                dismiss()
            }
            
            TextButton (
                text: String.localized("Save", table: "Settings"),
                colorConfig: .init(
                    text: isContentValid ? Color.white : Color.T_4,
                    background: isContentValid ? Color.blue : Color.T_6
                ),
                sizeConfig: .init(
                    height: 32,
                    cornerRadius: 6
                ),
                statusConfig: .init(
                    disabled: !isContentValid,
                    fillContainer: true
                )
            ) {
                saveMemory()
            }
        }
    }

    // MARK: - Private Functions

    private func saveMemory() {
        let bundleId: String? = if isGlobal {
            nil
        } else if let appURL = selectedAppURL {
            Bundle(url: appURL)?.bundleIdentifier
        } else {
            nil
        }

        let memory = Memory(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            appBundleIdentifier: bundleId
        )
        onSave(memory)
    }
}

// MARK: - ScopeSelectionButton

private struct ScopeSelectionButton: View {
    let text: String
    let icon: String
    let selected: Bool
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(selected ? Color.accentColor : Color.T_3)
                .frame(width: 16, height: 16)

            Text(text)
                .styleText(size: 12, weight: .regular)

            Spacer()

            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color.accentColor)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            selected
                ? Color.accentColor.opacity(0.1)
                : isHovered ? Color.S_0.opacity(0.05) : Color.clear
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { action() }
    }
}

// MARK: - AppRow

private struct AppRow: View {
    let url: URL
    let onSelect: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 16, height: 16)

                Text(url.deletingPathExtension().lastPathComponent)
                    .styleText(size: 12)

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isHovered ? Color.S_0.opacity(0.05) : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
