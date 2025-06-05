//
//  OCRDetailSheet.swift
//  Onit
//
//  Created by Alex Carmack on 2024.
//

import SwiftUI

struct OCRDetailSheet: View {
    let result: OCRComparisonResult
    @Environment(\.dismiss) private var dismiss
    @State private var showImageViewer = false
    @State private var thumbnailImage: NSImage?
    @State private var isLoadingThumbnail = true

    init(result: OCRComparisonResult) {
        self.result = result
        self._showImageViewer = State(initialValue: false)
        self._thumbnailImage = State(initialValue: nil)
        self._isLoadingThumbnail = State(initialValue: true)
        
        print("🔍 OCRDetailSheet created for app: \(result.appName) (\(result.appTitle)) - Match: \(result.matchPercentage)%")
    }

    var missingText: String {
        let ocrWords = result.ocrObservations
            .filter { !$0.isFoundInAccessibility }
            .map(\.text)
        
        return ocrWords.joined(separator: " ")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    if let bundleUrl = result.appBundleUrl {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: bundleUrl.path))
                            .resizable()
                            .frame(width: 24, height: 24)
                            .cornerRadius(6)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
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
                            .foregroundColor(result.matchPercentage < 50 ? .red : result.matchPercentage < 75 ? .yellow : .green)
                    }
                    
                    Spacer()
                    
                    Button("Close") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape)
                }
                .padding()
                
                Divider()
                
                // Screenshot Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Screenshots")
                        .font(.headline)
                    
                    if isLoadingThumbnail {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    } else if let thumbnailImage = thumbnailImage {
                        Button {
                            showImageViewer = true
                        } label: {
                            Image(nsImage: thumbnailImage
)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
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
                }
                .padding(.horizontal)
                .onAppear {
                    loadThumbnail()
                }
                
                Divider()
                
                // Text Comparison Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Text Comparison")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accessibility Text:")
                            .font(.system(size: 13, weight: .medium))
                        ScrollView {
                            Text(result.accessibilityText.isEmpty ? "No text found" : result.accessibilityText)
                                .font(.system(size: 11, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .frame(maxHeight: 120)
                        
                        Text("OCR Text:")
                            .font(.system(size: 13, weight: .medium))
                        ScrollView {
                            Text(result.ocrObservations.isEmpty ? "No text found" : result.ocrObservations.map(\.text).joined(separator: " "))
                                .font(.system(size: 11, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .frame(maxHeight: 120)
                        
                        if !missingText.isEmpty {
                            Text("Text Missing from Accessibility:")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                            ScrollView {
                                Text(missingText)
                                    .font(.system(size: 11, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                            .frame(maxHeight: 120)
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Export Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Options")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        Button("Export Accessibility Text") {
                            exportText(result.accessibilityText, filename: "\(result.appName)_accessibility")
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 12))
                        
                        Button("Export OCR Text") {
                            let ocrText = result.ocrObservations.map(\.text).joined(separator: "\n")
                            exportText(ocrText, filename: "\(result.appName)_ocr")
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 12))
                        
                        Button("Export Comparison Report") {
                            exportComparison()
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 12))
                        
                        Button("Save Screenshot") {
                            if let screenshot = result.screenshot {
                                saveScreenshot(screenshot)
                            }
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 12))
                        
                        if result.debugScreenshot != nil {
                            Button("Save OCR Debug Screenshot") {
                                if let screenshot = result.debugScreenshot {
                                    saveScreenshot(screenshot)
                                }
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 12))
                        }
                        
                        if result.debugAccessibilityScreenshot != nil {
                            Button("Save AX Debug Screenshot") {
                                if let screenshot = result.debugAccessibilityScreenshot {
                                    saveScreenshot(screenshot)
                                }
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 12))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .sheet(isPresented: $showImageViewer) {
            OCRImageViewerSheet(image: result.debugScreenshot ?? result.screenshot, result: result)
        }
    }
    
    // MARK: - Thumbnail Loading
    
    private func loadThumbnail() {
        guard let originalImage = result.debugScreenshot ?? result.screenshot else {
            return
        }
        
        Task {
            let thumbnail = await generateThumbnail(from: originalImage, maxSize: CGSize(width: 400, height: 300))
            
            await MainActor.run {
                self.thumbnailImage = thumbnail
                self.isLoadingThumbnail = false
            }
        }
    }
    
    private func generateThumbnail(from image: NSImage, maxSize: CGSize) async -> NSImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let originalSize = image.size
                let aspectRatio = originalSize.width / originalSize.height
                
                var newSize: CGSize
                if aspectRatio > maxSize.width / maxSize.height {
                    // Width is the limiting factor
                    newSize = CGSize(width: maxSize.width, height: maxSize.width / aspectRatio)
                } else {
                    // Height is the limiting factor
                    newSize = CGSize(width: maxSize.height * aspectRatio, height: maxSize.height)
                }
                
                let thumbnail = NSImage(size: newSize)
                thumbnail.lockFocus()
                image.draw(in: NSRect(origin: .zero, size: newSize))
                thumbnail.unlockFocus()
                
                continuation.resume(returning: thumbnail)
            }
        }
    }

    // MARK: - Export Functions
    
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

// MARK: - OCR Image Viewer Sheet

private struct OCRImageViewerSheet: View {
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
                        .foregroundColor(result.matchPercentage < 50 ? .red : result.matchPercentage < 75 ? .yellow : .green)
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
