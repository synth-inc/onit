import SwiftUI
import AppKit

struct TypeaheadTestCasesView: View {
    @State private var testCases: [TypedInputEntry] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedEntry: TypedInputEntry? = nil
    @State private var sortColumn: SortColumn = .timestamp
    @State private var sortAscending = false
    
    enum SortColumn {
        case timestamp, changeType, application
    }
    
    var filteredTestCases: [TypedInputEntry] {
        let filtered = searchText.isEmpty ? testCases : testCases.filter { entry in
            entry.applicationName.localizedCaseInsensitiveContains(searchText) ||
            entry.changeType?.localizedCaseInsensitiveContains(searchText) == true ||
            entry.addedText?.localizedCaseInsensitiveContains(searchText) == true ||
            entry.deletedText?.localizedCaseInsensitiveContains(searchText) == true
        }
        
        return filtered.sorted { lhs, rhs in
            let comparison: Bool
            switch sortColumn {
            case .timestamp:
                comparison = lhs.timestamp < rhs.timestamp
            case .changeType:
                comparison = (lhs.changeType ?? "") < (rhs.changeType ?? "")
            case .application:
                comparison = lhs.applicationName < rhs.applicationName
            }
            return sortAscending ? comparison : !comparison
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            headerSection
            
            if isLoading {
                ProgressView("Loading test cases...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if testCases.isEmpty {
                emptyStateView
            } else {
                testCasesTableView
            }
        }
        .onAppear {
            loadTestCases()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Typeahead Test Cases")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Refresh") {
                        loadTestCases()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                    
                    Button("Clear All") {
                        clearAllTestCases()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                }
            }
            
            HStack {
                TextField("Search test cases...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                
                Text("\(filteredTestCases.count) cases")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Test Cases Found")
                .font(.system(size: 16, weight: .medium))
            
            Text("Enable 'Collect local typeahead test cases' in General settings and use the app to generate test cases.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var testCasesTableView: some View {
        ScrollView([.vertical, .horizontal]) {
            LazyVStack(spacing: 1) {
                // Table header
                tableHeaderRow
                
                // Table rows
                ForEach(Array(filteredTestCases.enumerated()), id: \.element.timestamp) { index, entry in
                    testCaseRow(entry: entry, isEven: index % 2 == 0)
                }
            }
            .frame(minWidth: 1150, maxHeight: 800) // Ensure table has enough width to show all columns properly
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var tableHeaderRow: some View {
        HStack(spacing: 8) {
            sortableHeader("Time", column: .timestamp, width: 80)
            tableHeaderCellWithHelp("App", width: 100, help: "Application name (scroll horizontally in cells)")
            tableHeaderCellWithHelp("Text Before", width: 180, help: "Text before change (scroll horizontally in cells)")
            tableHeaderCellWithHelp("Text After", width: 180, help: "Text after change (scroll horizontally in cells)")
            tableHeaderCellWithHelp("Added", width: 120, help: "Added text (scroll horizontally in cells)")
            tableHeaderCellWithHelp("Deleted", width: 120, help: "Deleted text (scroll horizontally in cells)")
            sortableHeader("Type", column: .changeType, width: 80)
            tableHeaderCellWithHelp("Keystrokes", width: 150, help: "Full keystroke sequence (scroll horizontally in cells)")
            tableHeaderCell("Actions", width: 60)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .font(.system(size: 11, weight: .medium))
    }
    
    private func sortableHeader(_ title: String, column: SortColumn, width: CGFloat) -> some View {
        Button(action: {
            if sortColumn == column {
                sortAscending.toggle()
            } else {
                sortColumn = column
                sortAscending = true
            }
        }) {
            HStack(spacing: 2) {
                Text(title)
                if sortColumn == column {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: width, alignment: .leading)
        .foregroundColor(.primary)
    }
    
    private func tableHeaderCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .frame(width: width, alignment: .leading)
    }
    
    private func tableHeaderCellWithHelp(_ title: String, width: CGFloat, help: String) -> some View {
        Text(title)
            .frame(width: width, alignment: .leading)
            .help(help)
    }
    
    private func testCaseRow(entry: TypedInputEntry, isEven: Bool) -> some View {
        HStack(spacing: 8) {
            // Time
            Text(formatTime(entry.timestamp))
                .frame(width: 80, alignment: .leading)
                .font(.system(size: 10, design: .monospaced))
            
            // Application
            ScrollView(.horizontal, showsIndicators: false) {
                Text(entry.applicationName)
                    .font(.system(size: 10))
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: 100, height: 20, alignment: .leading)
            .help("Application name - scroll to see full name")
            
            // Text Before
            HStack(spacing: 4) {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(entry.precedingInputText + (entry.deletedText ?? "") + entry.followingInputText)
                        .font(.system(size: 10, design: .monospaced))
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(height: 20)
                .help("Scroll horizontally to see full text")
                
                Button(action: {
                    copyTextBefore(entry)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 8))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Copy full text before change")
            }
            .frame(width: 180, alignment: .leading)
            
            // Text After
            HStack(spacing: 4) {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(entry.currentText)
                        .font(.system(size: 10, design: .monospaced))
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(height: 20)
                .help("Scroll horizontally to see full text")
                
                Button(action: {
                    copyTextAfter(entry)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 8))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Copy full text after change")
            }
            .frame(width: 180, alignment: .leading)
            
            // Added Text
            ScrollView(.horizontal, showsIndicators: false) {
                Text(entry.addedText ?? "-")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(entry.addedText != nil ? .green : .secondary)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: 120, height: 20, alignment: .leading)
            .help("Added text - scroll to see full content")
            
            // Deleted Text
            ScrollView(.horizontal, showsIndicators: false) {
                Text(entry.deletedText ?? "-")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(entry.deletedText != nil ? .red : .secondary)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: 120, height: 20, alignment: .leading)
            .help("Deleted text - scroll to see full content")
            
            // Change Type
            Text(entry.changeType ?? "unknown")
                .frame(width: 80, alignment: .leading)
                .font(.system(size: 10))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(changeTypeColor(entry.changeType))
                .cornerRadius(4)
            
            // Keystrokes
            ScrollView(.horizontal, showsIndicators: false) {
                Text(entry.keystrokesArray.joined(separator: ", "))
                    .font(.system(size: 10, design: .monospaced))
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(width: 150, height: 20, alignment: .leading)
            .help("Full keystrokes - scroll to see all")
            
            // Actions
            Button("Copy") {
                copyTestCaseDetails(entry)
            }
            .buttonStyle(.plain)
            .font(.system(size: 10))
            .foregroundColor(.blue)
            .frame(width: 60, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isEven ? Color.clear : Color.gray.opacity(0.03))
        .onTapGesture {
            selectedEntry = entry
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    

    
    private func changeTypeColor(_ changeType: String?) -> Color {
        switch changeType {
        case "addition":
            return Color.green.opacity(0.1)
        case "deletion":
            return Color.red.opacity(0.1)
        case "modification":
            return Color.orange.opacity(0.1)
        default:
            return Color.gray.opacity(0.1)
        }
    }
    
    private func copyTestCaseDetails(_ entry: TypedInputEntry) {
        let fullTextBefore = entry.precedingInputText + (entry.deletedText ?? "") + entry.followingInputText
        let fullTextAfter = entry.currentText
        
        let details = """
        // Typeahead Test Case
        Old value: "\(fullTextBefore)"
        New value: "\(fullTextAfter)"
        Added text: "\(entry.addedText ?? "")"
        Deleted text: "\(entry.deletedText ?? "")"
        Change type: \(entry.changeType ?? "unknown")
        Keystrokes: \(entry.keystrokesArray)
        Application: \(entry.applicationName)
        Timestamp: \(entry.timestamp)
        
        // Test case template:
        testSpecialOperation(
            name: "\(entry.changeType?.capitalized ?? "Unknown") in \(entry.applicationName)",
            old: "\(fullTextBefore)",
            new: "\(fullTextAfter)",
            keystrokes: \(entry.keystrokesArray),
            expectedType: .\(entry.changeType ?? "modification"),
            expectedAdded: "\(entry.addedText ?? "")",
            expectedIndex: \(entry.estimatedChangeIndex ?? 0)
        )
        """
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(details, forType: .string)
    }
    
    private func copyTextBefore(_ entry: TypedInputEntry) {
        // Copy the full text before the change (reconstructed from preceding + deleted + following)
        let fullTextBefore = entry.precedingInputText + (entry.deletedText ?? "") + entry.followingInputText
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fullTextBefore, forType: .string)
    }
    
    private func copyTextAfter(_ entry: TypedInputEntry) {
        // Copy the full current text after the change
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(entry.currentText, forType: .string)
    }
    
    private func loadTestCases() {
        isLoading = true
        Task {
            let entries = await TypeaheadHistoryManager.shared.fetchTypedInputEntries(limit: 200)
            await MainActor.run {
                self.testCases = entries
                self.isLoading = false
            }
        }
    }
    
    private func clearAllTestCases() {
        Task {
            await TypeaheadHistoryManager.shared.clearAllTypedInputEntries()
            await MainActor.run {
                self.testCases = []
            }
        }
    }
}

#Preview {
    TypeaheadTestCasesView()
        .frame(width: 800, height: 600)
} 
