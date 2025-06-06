import SwiftUI
import Defaults

struct DebugModeTab: View {
    @ObservedObject private var debugManager = DebugManager.shared
    @State private var showOnlyFailures = true

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Debug")
                        .font(.system(size: 14))
                    HStack {
                        Text("Show debug window")
                            .font(.system(size: 13))
                        Spacer()
                        Toggle("", isOn: $debugManager.showDebugWindow)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                    
                    HStack {
                        Text("Enable OCR comparison for AutoContext")
                            .font(.system(size: 13))
                        Spacer()
                        Toggle("", isOn: $debugManager.enableOCRComparison)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                    
                    HStack {
                        Text("Auto OCR comparison on app switch")
                            .font(.system(size: 13))
                        Spacer()
                        Toggle("", isOn: $debugManager.enableAutoOCRComparison)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: debugManager.enableAutoOCRComparison) { _, newValue in
                                print("Auto OCR comparison toggled to: \(newValue)")
                                
                                if newValue {
                                    debugManager.startAutoOCRComparison()
                                } else {
                                    debugManager.stopAutoOCRComparison()
                                }
                                
                                print(debugManager.hasAutoOCRDelegate ? "AutoOCRDelegate exists after toggle" : "No AutoOCRDelegate after toggle")
                            }
                    }
                    
                    if !debugManager.ocrComparisonResults.isEmpty {
                        Divider()
                        
                        HStack {
                            Text("OCR Comparison Results")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(showOnlyFailures ? "Show All" : "Show Failures Only") {
                                    showOnlyFailures.toggle()
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                                
                                Button("Clear All") {
                                    debugManager.clearOCRComparisonResults()
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.red)
                                .font(.system(size: 12))
                            }
                        }
                        
                        Text(resultCountText)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        if !failingApps.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Failing Apps")
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.top, 16)
                                
                                LazyVStack(spacing: 4) {
                                    ForEach(failingApps, id: \.appName) { appSummary in
                                        FailingAppRow(appSummary: appSummary)
                                    }
                                }
                            }
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredResults.reversed()) { result in
                                    OCRComparisonResultRow(result: result)
                                }
                            }
                        }
                        .frame(minHeight: 500)
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 86)
        }
    }
    
    private var filteredResults: [OCRComparisonResult] {
        if showOnlyFailures {
            return debugManager.failedOCRResults
        } else {
            return debugManager.ocrComparisonResults
        }
    }
    
    private var resultCountText: String {
        let total = debugManager.ocrComparisonResults.count
        let failed = debugManager.failedOCRResults.count
        let successful = total - failed
        
        if showOnlyFailures {
            return "\(failed) failures (of \(total) total)"
        } else {
            return "\(total) total results (\(total - failed) successful, \(failed) failed)"
        }
    }
    
    private var failingApps: [AppComparisonSummary] {
        let groupedResults = Dictionary(grouping: debugManager.ocrComparisonResults) { $0.appName }
        
        return groupedResults.compactMap { (appName, results) in
            let failedCount = results.filter { $0.matchPercentage < 70 }.count
            guard failedCount > 0 else { return nil }
            
            let appBundleUrl = results.first?.appBundleUrl
            return AppComparisonSummary(
                appName: appName,
                appBundleUrl: appBundleUrl,
                failedCount: failedCount,
                totalCount: results.count
            )
        }.sorted { $0.failedCount > $1.failedCount } // Sort by most failures first
    }
}

struct AppComparisonSummary {
    let appName: String
    let appBundleUrl: URL?
    let failedCount: Int
    let totalCount: Int
}

struct FailingAppRow: View {
    let appSummary: AppComparisonSummary
    
    var body: some View {
        HStack(spacing: 8) {
            if let bundleUrl = appSummary.appBundleUrl {
                Image(nsImage: NSWorkspace.shared.icon(forFile: bundleUrl.path))
                    .resizable()
                    .frame(width: 16, height: 16)
                    .cornerRadius(4)
            }
            
            Text(appSummary.appName)
                .font(.system(size: 12, weight: .medium))
            
            Spacer()
            
            Text("\(appSummary.failedCount) / \(appSummary.totalCount) failed")
                .font(.system(size: 11))
                .foregroundColor(.red)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

struct OCRComparisonResultRow: View {
    @ObservedObject private var debugManager = DebugManager.shared
    let result: OCRComparisonResult
    @State private var isExpanded = false
   
    @State private var showImageViewer = false
    
    var missingText: String {
        let accessibilityWords = Set(result.accessibilityText.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 1 })
        let ocrWords = result.ocrObservations
            .filter { !$0.isFoundInAccessibility }
            .map(\.text)
        
        return ocrWords.joined(separator: " ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let bundleUrl = result.appBundleUrl {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: bundleUrl.path))
                        .resizable()
                        .frame(width: 16, height: 16)
                        .cornerRadius(4)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.appName)
                        .font(.system(size: 12, weight: .medium))
                    if result.appTitle != result.appName {
                        Text(result.appTitle.count > 50 ? result.appTitle.prefix(50) + "..." : result.appTitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Text("\(result.matchPercentage)% match")
                        .font(.system(size: 11))
                        .foregroundColor(result.matchPercentage < 70 ? .red : .secondary)
                }
                
                Spacer()
                
                Text(DateFormatter.shortDateTime.string(from: result.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Button(isExpanded ? "Collapse" : "Details") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.blue)
                
                Button(role: .destructive) {
                    debugManager.removeOCRComparisonResult(result)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            
            if let debugImage = result.debugScreenshot ?? result.screenshot {
                Button {
                    showImageViewer = true
                } label: {
                    Image(nsImage: debugImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 120)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Click to view full size")
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accessibility Text:")
                            .font(.system(size: 11, weight: .medium))
                        Text(result.accessibilityText.isEmpty ? "No text found" : result.accessibilityText)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                            .frame(maxHeight: 100)
                        
                        Text("OCR Text:")
                            .font(.system(size: 11, weight: .medium))
                        Text(result.ocrObservations.isEmpty ? "No text found" : result.ocrObservations.map(\.text).joined(separator: " "))
                            .font(.system(size: 10, design: .monospaced))
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                            .frame(maxHeight: 100)
                        
                        if !missingText.isEmpty {
                            Text("Text Missing from Accessibility:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red)
                            Text(missingText)
                                .font(.system(size: 10, design: .monospaced))
                                .padding(8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(4)
                                .frame(maxHeight: 100)
                        }
                        
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Button("Export Accessibility Text...") {
                                    exportText(result.accessibilityText, filename: "\(result.appName)_accessibility")
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 11))
                                .foregroundColor(.blue)
                                
                                Button("Export OCR Text...") {
                                    let ocrText = result.ocrObservations.map(\.text).joined(separator: "\n")
                                    exportText(ocrText, filename: "\(result.appName)_ocr")
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 11))
                                .foregroundColor(.blue)
                                
                                Button("Export Comparison...") {
                                    exportComparison()
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 11))
                                .foregroundColor(.blue)
                                
                                Button("Save Screenshot...") {
                                    if let screenshot = result.debugScreenshot ?? result.screenshot {
                                        saveScreenshot(screenshot)
                                    }
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 11))
                                .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .sheet(isPresented: $showImageViewer) {
            ImageViewerSheet(image: result.debugScreenshot ?? result.screenshot, result: result)
        }
    }
    
    private func exportText(_ text: String, filename: String) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "\(filename)_\(Int(result.timestamp.timeIntervalSince1970)).txt"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try text.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to export text: \(error)")
                }
            }
        }
    }
    
    private func exportComparison() {
        let ocrText = result.ocrObservations.map(\.text).joined(separator: "\n")
        let missingText = result.ocrObservations
            .filter { !$0.isFoundInAccessibility }
            .map(\.text)
            .joined(separator: "\n")
        
        let comparisonReport = """
        OCR Comparison Report
        ====================
        
        App: \(result.appName)
        Window: \(result.appTitle)
        Date: \(DateFormatter.fullDateTime.string(from: result.timestamp))
        Match Percentage: \(result.matchPercentage)%
        
        Accessibility Text
        ------------------
        \(result.accessibilityText.isEmpty ? "No text found" : result.accessibilityText)
        
        OCR Text
        --------
        \(ocrText.isEmpty ? "No text found" : ocrText)
        
        Text Missing from Accessibility
        -------------------------------
        \(missingText.isEmpty ? "None" : missingText)
        
        OCR Observations Details
        -----------------------
        \(result.ocrObservations.enumerated().map { index, obs in
            "Observation \(index + 1): \"\(obs.text)\" (Found in accessibility: \(obs.isFoundInAccessibility ? "Yes" : "No"), Match: \(obs.percentageMatched)%)"
        }.joined(separator: "\n"))
        """
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "\(result.appName)_comparison_\(Int(result.timestamp.timeIntervalSince1970)).txt"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try comparisonReport.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to export comparison report: \(error)")
                }
            }
        }
    }
    
    private func saveScreenshot(_ image: NSImage) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "\(result.appName)_\(Int(result.timestamp.timeIntervalSince1970)).png"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                if let imageData = image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: imageData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    try? pngData.write(to: url)
                }
            }
        }
    }
}

struct ImageViewerSheet: View {
    let image: NSImage?
    let result: OCRComparisonResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(result.appName)
                        .font(.title2)
                        .fontWeight(.medium)
                    if result.appTitle != result.appName {
                        Text(result.appTitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Text("\(result.matchPercentage)% accessibility match")
                        .font(.subheadline)
                        .foregroundColor(result.matchPercentage < 70 ? .red : .green)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()
            
            if let image = image {
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            HStack {
                Spacer()
                Button("Save Image...") {
                    saveImage()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 400)
        .padding()
    }
    
    private func saveImage() {
        guard let image = image else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "\(result.appName)_debug_\(Int(result.timestamp.timeIntervalSince1970)).png"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                if let imageData = image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: imageData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    try? pngData.write(to: url)
                }
            }
        }
    }
}

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        return formatter
    }()
}

#Preview {
    DebugModeTab()
}
