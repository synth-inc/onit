//
//  HighlightedTextBoundTrainingDataReviewView.swift
//  Onit
//
//  Created by Kévin Naudin on 06/27/2025.
//

import SwiftUI
import Defaults

struct HighlightedTextBoundTrainingDataReviewView: View {
    @ObservedObject private var trainingDataManager = HighlightedTextBoundTrainingDataManager.shared
    @Default(.quickEditConfig) var quickEditConfig
    
    @State private var samples: [HighlightedTextBoundTrainingSample] = []
    @State private var isLoading = false
    @State private var currentPage = 0
    @State private var hasMoreData = true
    @State private var detailWindowController: HighlightedTextBoundTrainingSampleDetailWindowController?
    @State private var validatedCount = 0
    @State private var unvalidatedCount = 0
    
    private let itemsPerPage = 10
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            
            if !samples.isEmpty {
                samplesGridView
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading training data...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
                .padding()
            }
            
            if hasMoreData && !samples.isEmpty {
                loadMoreButton
            }
        }
        .padding()
        .onAppear {
            loadInitialData()
        }
        .onChange(of: trainingDataManager.samplesCount) { _, _ in
            refreshData()
        }
        .onChange(of: validatedCount) { _, _ in
            refreshData()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Training Data Review")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Toggle("Enable Capture", isOn: $quickEditConfig.shouldCaptureTrainingData)
                    .toggleStyle(.switch)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(trainingDataManager.samplesCount) total samples", systemImage: "photo.stack")
                        .foregroundColor(Color.secondary)
                    
                    HStack(spacing: 16) {
                        Label("\(validatedCount) validated", systemImage: "checkmark.circle.fill")
                            .foregroundColor(Color.green)
                        
                        Label("\(unvalidatedCount) to review", systemImage: "circle")
                            .foregroundColor(Color.orange500)
                    }
                    .font(.caption)
                }
                
                Spacer()
                
                if trainingDataManager.isCapturing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Capturing...")
                            .font(.caption)
                            .foregroundColor(Color.secondary)
                    }
                }
            }
            
            Text("Review and edit bounding boxes for training data. Only unvalidated samples are shown. Click on an image to edit its bounding box.")
                .font(.caption)
                .foregroundColor(Color.secondary)
        }
    }
    
    private var samplesGridView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(samples, id: \.id) { sample in
                    SampleRowView(
                        sample: sample,
                        onTap: {
                            showDetailWindow(for: sample)
                        }
                    )
                }
            }
            .padding(.vertical)
        }
    }
    
    private var loadMoreButton: some View {
        HStack {
            Spacer()
            Button("Load More") {
                loadMoreData()
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)
            Spacer()
        }
    }
    
    private func loadInitialData() {
        currentPage = 0
        samples = []
        hasMoreData = true
        loadMoreData()
        loadStatistics()
    }
    
    private func refreshData() {
        loadInitialData()
    }
    
    private func loadMoreData() {
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        
        Task {
            let newSamples = await trainingDataManager.getUnvalidatedSamples(
                offset: currentPage * itemsPerPage,
                limit: itemsPerPage
            )
            
            await MainActor.run {
                if newSamples.count < itemsPerPage {
                    hasMoreData = false
                }
                
                samples.append(contentsOf: newSamples)
                currentPage += 1
                isLoading = false
            }
        }
    }
    
    private func loadStatistics() {
        Task {
            let validated = await trainingDataManager.getValidatedCount()
            let unvalidated = await trainingDataManager.getUnvalidatedCount()
            
            await MainActor.run {
                self.validatedCount = validated
                self.unvalidatedCount = unvalidated
            }
        }
    }
    
    private func showDetailWindow(for sample: HighlightedTextBoundTrainingSample) {
        detailWindowController?.window?.close()
        
        detailWindowController = HighlightedTextBoundTrainingSampleDetailWindowController(
            sample: sample,
            onSave: { updatedSample in
                saveSample(updatedSample)
            },
            onDelete: {
                deleteSample(sample)
                detailWindowController = nil
            }
        )
        detailWindowController?.showWindow()
    }
    
    private func saveSample(_ updatedSample: HighlightedTextBoundTrainingSample) {
        Task {
            await trainingDataManager.updateSample(updatedSample)
            
            await MainActor.run {
                loadStatistics()
            }
        }
    }
    
    private func deleteSample(_ sample: HighlightedTextBoundTrainingSample) {
        Task {
            await trainingDataManager.delete(sample: sample)
            
            await MainActor.run {
                loadStatistics()
            }
        }
    }
}

struct SampleRowView: View {
    let sample: HighlightedTextBoundTrainingSample
    let onTap: () -> Void
    
    @State private var thumbnailImage: NSImage?
    @State private var isLoadingThumbnail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                if let thumbnailImage = thumbnailImage {
                    Image(nsImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                        .clipped()
                } else if isLoadingThumbnail {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(8)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color.secondary)
                                Text("Image not available")
                                    .font(.caption)
                                    .foregroundColor(Color.secondary)
                            }
                        )
                }
            }
            .onAppear {
                loadThumbnailIfNeeded()
            }
            .onDisappear {
                thumbnailImage = nil
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(sample.appName)
                        .font(.headline)
                        .foregroundColor(Color.S_0)
                    
                    Spacer()
                    
                    Text(DateFormatters.mediumWithTime.string(from: sample.createdAt))
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                }
                
                Text("Highlighted text:")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
                
                Text(sample.selectedText)
                    .font(.body)
                    .foregroundColor(Color.S_0)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private func loadThumbnailIfNeeded() {
        guard thumbnailImage == nil && !isLoadingThumbnail else { return }
        
        isLoadingThumbnail = true
        
        Task {
            let base64String = sample.screenshotBase64
            let thumbnail = await createThumbnail(from: base64String)
            
            await MainActor.run {
                self.thumbnailImage = thumbnail
                self.isLoadingThumbnail = false
            }
        }
    }
    
    private func createThumbnail(from base64String: String) async -> NSImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                guard let imageData = Data(base64Encoded: base64String),
                      let originalImage = NSImage(data: imageData) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let targetSize = CGSize(width: 400, height: 300)
                let originalSize = originalImage.size
                
                let scale = min(targetSize.width / originalSize.width, targetSize.height / originalSize.height)
                let thumbnailSize = CGSize(
                    width: originalSize.width * scale,
                    height: originalSize.height * scale
                )
                
                let thumbnail = NSImage(size: thumbnailSize)
                thumbnail.lockFocus()
                originalImage.draw(in: NSRect(origin: .zero, size: thumbnailSize))
                thumbnail.unlockFocus()
                
                continuation.resume(returning: thumbnail)
            }
        }
    }
}
