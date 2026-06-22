//
//  SettingsSidekickDebug.swift
//  Onit
//
//  Created by Kévin Naudin on 12/04/2025.
//

import SwiftUI
import Defaults

struct SettingsSidekickDebug: View {
    // MARK: - Observations
    
    @ObservedObject private var debugManager = DebugManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    // MARK: - States
    
    @State private var showOnlyFailures = false
    @State private var loadedItemsCount = 5
    @State private var isLoadingMore = false
    @State private var searchText = ""
    
    // MARK: - Private Variables

    private let itemsPerPage = 20
    
    // MARK: - Private Variables
    
    private var filteredResults: [OCRComparisonResult] {
        let baseResults = showOnlyFailures ? debugManager.failedOCRResults : debugManager.ocrComparisonResults

        let searchFiltered = searchText.isEmpty ? baseResults : baseResults.filter { result in
            result.appName.localizedCaseInsensitiveContains(searchText)
        }

        return searchFiltered.reversed()
    }

    private var visibleResults: [OCRComparisonResult] {
        let results = filteredResults
        return Array(results.prefix(loadedItemsCount))
    }

    private var canLoadMore: Bool {
        loadedItemsCount < filteredResults.count
    }
    
    private var resultCountText: String {
        let allResults = debugManager.ocrComparisonResults
        let allFailed = debugManager.failedOCRResults
        let filteredCount = filteredResults.count

        if !searchText.isEmpty {
            if showOnlyFailures {
                let filteredFailed = allFailed.filter { $0.appName.localizedCaseInsensitiveContains(searchText) }.count
                return String.localized("%d failures matching '%@' (of %d total failures) - Showing %d", table: "Sidekick", filteredFailed, searchText, allFailed.count, min(loadedItemsCount, filteredCount))
            } else {
                return String.localized("%d results matching '%@' (of %d total) - Showing %d", table: "Sidekick", filteredCount, searchText, allResults.count, min(loadedItemsCount, filteredCount))
            }
        } else {
            let total = allResults.count
            let failed = allFailed.count
            let successful = total - failed

            if showOnlyFailures {
                return String.localized("%d failures (of %d total) - Showing %d", table: "Sidekick", failed, total, min(loadedItemsCount, failed))
            } else {
                return String.localized("%d total results (%d successful, %d failed) - Showing %d", table: "Sidekick", total, successful, failed, min(loadedItemsCount, total))
            }
        }
    }

    private var failingApps: [AppComparisonSummary] {
        let allResults = debugManager.ocrComparisonResults

        let resultsToGroup = searchText.isEmpty ? allResults : allResults.filter { result in
            result.appName.localizedCaseInsensitiveContains(searchText)
        }

        let groupedResults = Dictionary(grouping: resultsToGroup) { $0.appName }

        return groupedResults.compactMap { (appName, results) in
            let failedCount = results.filter { $0.matchPercentage < 70 }.count
            guard failedCount > 0 else { return nil }

            let appBundleUrl = results.first?.appBundleUrl
            let failurePercentage = Double(failedCount) / Double(results.count) * 100.0
            return AppComparisonSummary(
                appName: appName,
                appBundleUrl: appBundleUrl,
                failedCount: failedCount,
                totalCount: results.count,
                failurePercentage: failurePercentage
            )
        }.sorted { $0.failurePercentage > $1.failurePercentage }
    }
    
    // MARK: - Body

    var body: some View {
        debugSection
        ocrComparisonSection

        if !debugManager.ocrComparisonResults.isEmpty {
            ocrResultsSection
        }
    }

    // MARK: - Child Components: Debug Section

    private var debugSection: some View {
        SettingsPageSection(title: .init(text: String.localized("Debug", table: "Sidekick"))) {
            SettingsPageSubsection(
                header: .init(
                    title: String.localized("Show debug log", table: "Sidekick"),
                    subtitle: String.localized("Display debug log output inline below.", table: "Sidekick")
                ),
                isOn: $debugManager.showDebugWindow
            )

            if debugManager.showDebugWindow {
                DividerHorizontal()
                debugLogView
            }
        }
    }

    private var debugLogView: some View {
        SettingsPageSubsection(
            vertical: .init(
                spacing: 8
            ),
            header: .init(
                title: String.localized("Debug Log", table: "Sidekick"),
                subtitle: String.localized("Sidekick debug information.", table: "Sidekick")
            )
        ) {
            Button {
                debugManager.debugText = ""
            } label: {
                Text(String.localized("Clear", table: "Sidekick"))
            }
            .buttonStyle(PlainButtonStyle())
            .styleText(
                size: 11,
                color: Color.blue
            )

            TextEditor(text: $debugManager.debugText)
                .font(.system(size: 10, design: .monospaced))
                .frame(height: 150)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
        }
    }

    // MARK: - Child Components: OCR Comparison Section

    private var ocrComparisonSection: some View {
        SettingsPageSection(title: .init(text: String.localized("OCR Comparison", table: "Sidekick"))) {
            SettingsPageSubsection(
                header: .init(
                    title: String.localized("Enable OCR comparison for AutoContext", table: "Sidekick"),
                    subtitle: String.localized("Compare OCR results with accessibility text.", table: "Sidekick")
                ),
                isOn: $debugManager.enableOCRComparison
            )

            DividerHorizontal()

            SettingsPageSubsection(
                header: .init(
                    title: String.localized("Auto OCR comparison on app switch", table: "Sidekick"),
                    subtitle: String.localized("Automatically run OCR comparison when switching apps.", table: "Sidekick")
                ),
                isOn: $debugManager.enableAutoOCRComparison
            )
            .onChange(of: debugManager.enableAutoOCRComparison) { _, newValue in
                if newValue {
                    debugManager.startAutoOCRComparison()
                } else {
                    debugManager.stopAutoOCRComparison()
                }
            }
        }
    }
    
    // MARK: - Child Components: OCR Results Section

    private var ocrResultsSection: some View {
        SettingsPageSection(title: .init(text: String.localized("OCR Comparison Results", table: "Sidekick"))) {
            HStack(spacing: 12) {
                Button(showOnlyFailures ? String.localized("Show All", table: "Sidekick") : String.localized("Show Failures Only", table: "Sidekick")) {
                    showOnlyFailures.toggle()
                    loadedItemsCount = itemsPerPage
                }
                .buttonStyle(.plain)
                .styleText(size: 12, color: Color.blue)

                Button(String.localized("Clear All", table: "Sidekick")) {
                    debugManager.clearOCRComparisonResults()
                    loadedItemsCount = itemsPerPage
                }
                .buttonStyle(.plain)
                .styleText(size: 12, color: Color.red500)
            }

            SettingsPageSubsection(
                vertical: .init(spacing: 8)
            ) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.secondary)
                        .font(.system(size: 12))

                    TextField(String.localized("Search by app name...", table: "Sidekick"), text: $searchText)
                        .textFieldStyle(.plain)
                        .styleText(size: 12)
                        .onChange(of: searchText) { _, _ in
                            loadedItemsCount = itemsPerPage
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)

                Text(resultCountText)
                    .styleText(size: 12, color: Color.S_2)
            }

            if !failingApps.isEmpty {
                failingAppsSection
            }

            resultsListSection
        }
    }

    private var failingAppsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsPageSubsection(
                header: .init(
                    title: String.localized("Failing Apps", table: "Sidekick")
                )
            ) {
                Button(String.localized("Copy Report", table: "Sidekick")) {
                    copyFailingAppsReport()
                }
                .buttonStyle(.plain)
                .styleText(size: 12, color: Color.blue)
            }

            SettingsPageSubsection {
                LazyVStack(spacing: 4) {
                    ForEach(failingApps, id: \.appName) { appSummary in
                        FailingAppRow(appSummary: appSummary)
                    }
                }
            }
        }
    }

    private var resultsListSection: some View {
        VStack(spacing: 8) {
            LazyVStack(spacing: 8) {
                ForEach(visibleResults) { result in
                    OCRComparisonResultRow(result: result)
                        .onAppear {
                            if result.id == visibleResults.last?.id {
                                loadMoreIfNeeded()
                            }
                        }
                }
            }

            if canLoadMore {
                if isLoadingMore {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(String.localized("Loading more results...", table: "Sidekick"))
                            .styleText(size: 12, color: Color.S_2)
                    }
                    .padding()
                } else {
                    Button(String.localized("Load More Results", table: "Sidekick")) {
                        loadMoreResults()
                    }
                    .buttonStyle(.plain)
                    .styleText(size: 12, color: Color.blue)
                    .padding()
                }
            }
        }
        .frame(minHeight: 300)
    }
    
    // MARK: - Private Functions

    private func loadMoreResults() {
        guard !isLoadingMore else { return }

        isLoadingMore = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let newCount = min(loadedItemsCount + itemsPerPage, filteredResults.count)
            loadedItemsCount = newCount
            isLoadingMore = false
        }
    }

    private func loadMoreIfNeeded() {
        if filteredResults.count - loadedItemsCount <= 5 {
            loadMoreResults()
        }
    }

    private func copyFailingAppsReport() {
        let copyableReport: String = failingApps.map { app in
            let emoji: String
            if app.failurePercentage > 50 {
                emoji = "🔴"
            } else if app.failurePercentage >= 25 {
                emoji = "🟡"
            } else {
                emoji = "🟢"
            }

            return "\(emoji) \(app.appName): \(app.failedCount)/\(app.totalCount) failed (\(Int(app.failurePercentage.rounded()))%)"
        }.joined(separator: "\n")

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(copyableReport, forType: .string)
    }
}

// MARK: - Supporting Types

struct AppComparisonSummary {
    let appName: String
    let appBundleUrl: URL?
    let failedCount: Int
    let totalCount: Int
    let failurePercentage: Double
}

struct FailingAppRow: View {
    let appSummary: AppComparisonSummary

    private var failureColor: Color {
        if appSummary.failurePercentage < 30 {
            return Color.green
        } else if appSummary.failurePercentage <= 50 {
            return Color.yellow
        } else {
            return Color.red500
        }
    }

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

            Text(String.localized("%d / %d failed (%d%%)", table: "Sidekick", appSummary.failedCount, appSummary.totalCount, Int(appSummary.failurePercentage.rounded())))
                .font(.system(size: 11))
                .foregroundColor(failureColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(failureColor.opacity(0.1))
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
    @ObservedObject private var localizationManager = LocalizationManager.shared
    let result: OCRComparisonResult
    @State private var isExpanded = false
    @State private var showImageViewer = false

    var missingText: String {
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
                            .foregroundColor(Color.secondary)
                            .lineLimit(1)
                    }
                    Text(String.localized("%d%% match", table: "Sidekick", result.matchPercentage))
                        .font(.system(size: 11))
                        .foregroundColor(result.matchPercentage < 70 ? Color.red500 : Color.secondary)
                }

                Spacer()

                Text(DateFormatter.shortDateTime.string(from: result.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(Color.secondary)

                Button(isExpanded ? String.localized("Collapse", table: "Sidekick") : String.localized("Details", table: "Sidekick")) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(Color.blue)

                Button(role: .destructive) {
                    debugManager.removeOCRComparisonResult(result)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(Color.red500.opacity(0.8))
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }

            if isExpanded, let debugImage = result.debugScreenshot ?? result.screenshot {
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
                .help(String.localized("Click to view full size", table: "Sidekick"))
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String.localized("Accessibility Text:", table: "Sidekick"))
                            .font(.system(size: 11, weight: .medium))
                        ScrollView {
                            Text(result.accessibilityText.isEmpty ? String.localized("No text found", table: "Sidekick") : result.accessibilityText)
                                .font(.system(size: 10, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .frame(maxHeight: 100)

                        Text(String.localized("OCR Text:", table: "Sidekick"))
                            .font(.system(size: 11, weight: .medium))
                        ScrollView {
                            Text(result.ocrObservations.isEmpty ? String.localized("No text found", table: "Sidekick") : result.ocrObservations.map(\.text).joined(separator: " "))
                                .font(.system(size: 10, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .frame(maxHeight: 100)

                        if !missingText.isEmpty {
                            Text(String.localized("Text Missing from Accessibility:", table: "Sidekick"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.red500)
                            ScrollView {
                                Text(missingText)
                                    .font(.system(size: 10, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(8)
                            .background(Color.red500.opacity(0.1))
                            .cornerRadius(4)
                            .frame(maxHeight: 100)
                        }

                        HStack {
                            Spacer()
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Button(String.localized("Export Accessibility Text →", table: "Sidekick")) {
                                        exportText(result.accessibilityText, filename: "\(result.appName)_accessibility")
                                    }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.blue)

                                    Button(String.localized("Export OCR Text →", table: "Sidekick")) {
                                        let ocrText = result.ocrObservations.map(\.text).joined(separator: "\n")
                                        exportText(ocrText, filename: "\(result.appName)_ocr")
                                    }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.blue)

                                    Button(String.localized("Export Comparison →", table: "Sidekick")) {
                                        exportComparison()
                                    }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.blue)

                                    Button(String.localized("Save Screenshot →", table: "Sidekick")) {
                                        if let screenshot = result.screenshot {
                                            saveScreenshot(screenshot)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.blue)

                                    Button(String.localized("Save OCR Debug Screenshot →", table: "Sidekick")) {
                                        if let screenshot = result.debugScreenshot {
                                            saveScreenshot(screenshot)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.blue)

                                    Button(String.localized("Save AX Debug Screenshot →", table: "Sidekick")) {
                                        if let screenshot = result.debugAccessibilityScreenshot {
                                            saveScreenshot(screenshot)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.blue)
                                }
                                Spacer()
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
    @ObservedObject private var localizationManager = LocalizationManager.shared
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
                            .foregroundColor(Color.secondary)
                    }
                    Text(String.localized("%d%% accessibility match", table: "Sidekick", result.matchPercentage))
                        .font(.subheadline)
                        .foregroundColor(result.matchPercentage < 70 ? Color.red500 : Color.green)
                }

                Spacer()

                Button(String.localized("Close", table: "Sidekick")) {
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
                Button(String.localized("Save Image...", table: "Sidekick")) {
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

// MARK: - DateFormatter Extensions

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
