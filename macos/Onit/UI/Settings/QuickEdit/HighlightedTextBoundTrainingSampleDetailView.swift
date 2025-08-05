//
//  HighlightedTextBoundTrainingSampleDetailView.swift
//  Onit
//
//  Created by Kévin Naudin on 06/27/2025.
//

import SwiftUI

struct HighlightedTextBoundTrainingSampleDetailView: View {
    let sample: HighlightedTextBoundTrainingSample
    let onSave: (HighlightedTextBoundTrainingSample) -> Void
    let onDelete: () -> Void
    let onClose: () -> Void
    
    @State private var editableBoundingBox: NormalizedBoundingBox
    @State private var hasChanges = false
    @State private var showDeleteAlert = false
    @State private var isPanelExpanded = false
    
    init(sample: HighlightedTextBoundTrainingSample, onSave: @escaping (HighlightedTextBoundTrainingSample) -> Void, onDelete: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.sample = sample
        self.onSave = onSave
        self.onDelete = onDelete
        self.onClose = onClose
        self._editableBoundingBox = State(initialValue: sample.boundingBox)
    }
    
    var body: some View {
        ZStack {
            fullScreenImageView
            
            HStack {
                Spacer()
                
                if isPanelExpanded {
                    expandedSidePanel
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    collapsedSidePanel
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .frame(width: 1200, height: 800)
        .onChange(of: editableBoundingBox) { _, _ in
            hasChanges = editableBoundingBox != sample.boundingBox
        }
        .alert("Delete Training Sample", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
                onClose()
            }
        } message: {
            Text("Are you sure you want to permanently delete this training sample? This action cannot be undone.")
        }
    }
    
    private var collapsedSidePanel: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPanelExpanded = true
                }
            }) {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 18))
                    .foregroundColor(Color.S_0)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            VStack(spacing: 8) {
                Button(action: {
                    let updatedSample = createUpdatedSample(isValidated: true)
                    onSave(updatedSample)
                    onClose()
                }) {
                    Image(systemName: hasChanges ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 16))
                        .foregroundColor(Color.S_0)
                        .frame(width: 40, height: 40)
                        .background(hasChanges ? Color.green.opacity(0.8) : Color.gray.opacity(0.7))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(sample.isValidated && !hasChanges)
                
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(Color.S_0)
                        .frame(width: 40, height: 40)
                        .background(Color.red500.opacity(0.8))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(Color.S_0)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape)
            }
        }
        .padding(16)
    }
    
    private var fullScreenImageView: some View {
        GeometryReader { geometry in
            if let imageData = Data(base64Encoded: sample.screenshotBase64),
               let nsImage = NSImage(data: imageData) {
                
                ZStack {
                    Color.black
                    
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay(
                            GeometryReader { imageGeometry in
                                EditableBoundingBoxOverlay(
                                    boundingBox: $editableBoundingBox,
                                    imageGeometry: imageGeometry,
                                    originalImageSize: nsImage.size
                                )
                            }
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(Color.S_0)
                            Text("Image not available")
                                .font(.title)
                                .foregroundColor(Color.S_0)
                        }
                    )
            }
        }
    }
    
    private var expandedSidePanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Sample Details")
                    .font(.headline)
                    .foregroundColor(Color.S_0)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPanelExpanded = false
                    }
                }) {
                    Image(systemName: "sidebar.right")
                        .font(.system(size: 16))
                        .foregroundColor(Color.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Text")
                        .font(.headline)
                        .foregroundColor(Color.S_0)
                    
                    ScrollView {
                        Text(sample.selectedText)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                    }
                    .frame(maxHeight: 120)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Application")
                        .font(.headline)
                        .foregroundColor(Color.S_0)
                    
                    Text(sample.appName)
                        .font(.body)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Created")
                        .font(.headline)
                        .foregroundColor(Color.S_0)
                    
                    Text(DateFormatters.mediumWithTime.string(from: sample.createdAt))
                        .font(.body)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                }
                
                HStack {
                    Text("Status:")
                        .font(.headline)
                        .foregroundColor(Color.S_0)
                    
                    HStack(spacing: 4) {
                        Image(systemName: sample.isValidated ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(sample.isValidated ? Color.green : Color.secondary)
                        Text(sample.isValidated ? "Validated" : "Not validated")
                            .foregroundColor(sample.isValidated ? Color.green : Color.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            Divider()
            
            HStack {
                Button("Delete") {
                    showDeleteAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(Color.red500)
                
                Spacer()
                
                if hasChanges {
                    Button("Approve and Update") {
                        let updatedSample = createUpdatedSample(isValidated: true)
                        onSave(updatedSample)
                        onClose()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Validate") {
                        let updatedSample = createUpdatedSample(isValidated: true)
                        onSave(updatedSample)
                        onClose()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(sample.isValidated)
                }
            }
            .padding(20)
        }
        .frame(width: 350)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.95))
        .cornerRadius(12, corners: [.topLeft, .bottomLeft])
        .shadow(radius: 10)
    }
    
    private func createUpdatedSample(isValidated: Bool) -> HighlightedTextBoundTrainingSample {
        return HighlightedTextBoundTrainingSample(
            id: sample.id,
            createdAt: sample.createdAt,
            screenshotBase64: sample.screenshotBase64,
            selectedText: sample.selectedText,
            boundingBox: editableBoundingBox,
            primaryScreenFrame: sample.primaryScreenFrame,
            appScreenFrame: sample.appScreenFrame,
            appScreenMenuBarHeight: sample.appScreenMenuBarHeight,
            appName: sample.appName,
            isValidated: isValidated
        )
    }
    

}

struct EditableBoundingBoxOverlay: View {
    @Binding var boundingBox: NormalizedBoundingBox
    let imageGeometry: GeometryProxy
    let originalImageSize: CGSize
    
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var dragOffset = CGSize.zero
    @State private var resizeAnchor: ResizeAnchor = .bottomRight
    @State private var initialBoundingBox: NormalizedBoundingBox = NormalizedBoundingBox(x: 0, y: 0, width: 0, height: 0)
    @State private var dragStartThreshold: CGFloat = 1.0
    
    enum ResizeAnchor {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    var body: some View {
        let displayX = boundingBox.x * imageGeometry.size.width
        let displayY = (1.0 - boundingBox.y - boundingBox.height) * imageGeometry.size.height
        let displayWidth = boundingBox.width * imageGeometry.size.width
        let displayHeight = boundingBox.height * imageGeometry.size.height
        
        ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(Color.red500, lineWidth: 1)
                .background(Color.red500.opacity(0.1))
                .frame(width: displayWidth, height: displayHeight)
                .offset(
                    x: displayX + (isDragging ? dragOffset.width : 0),
                    y: displayY + (isDragging ? dragOffset.height : 0)
                )
                .gesture(
                    DragGesture(minimumDistance: dragStartThreshold)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                initialBoundingBox = boundingBox
                            }
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            let normalizedDeltaX = value.translation.width / imageGeometry.size.width
                            let normalizedDeltaY = -value.translation.height / imageGeometry.size.height
                            
                            let newX = initialBoundingBox.x + normalizedDeltaX
                            let newY = initialBoundingBox.y + normalizedDeltaY
                            
                            let clampedX = max(0, min(1 - boundingBox.width, newX))
                            let clampedY = max(0, min(1 - boundingBox.height, newY))
                            
                            boundingBox = NormalizedBoundingBox(
                                x: clampedX,
                                y: clampedY,
                                width: boundingBox.width,
                                height: boundingBox.height
                            )
                            
                            isDragging = false
                            dragOffset = .zero
                        }
                )
            
            ForEach([ResizeAnchor.topLeft, .topRight, .bottomLeft, .bottomRight], id: \.self) { anchor in
                resizeHandle(for: anchor, displayX: displayX, displayY: displayY, displayWidth: displayWidth, displayHeight: displayHeight)
            }
        }
    }
    
    private func resizeHandle(for anchor: ResizeAnchor, displayX: CGFloat, displayY: CGFloat, displayWidth: CGFloat, displayHeight: CGFloat) -> some View {
        let handleSize: CGFloat = 10
        
        let (handleOffsetX, handleOffsetY) = handleOffset(for: anchor, displayX: displayX, displayY: displayY, displayWidth: displayWidth, displayHeight: displayHeight)
        
        return Circle()
            .fill(Color.red500.opacity(0.01))
            .frame(width: handleSize, height: handleSize)
            .offset(
                x: handleOffsetX - handleSize/2 + (isDragging ? dragOffset.width : 0),
                y: handleOffsetY - handleSize/2 + (isDragging ? dragOffset.height : 0)
            )
            .scaleEffect(isResizing && resizeAnchor == anchor ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isResizing)
            .gesture(
                DragGesture(minimumDistance: 2.0)
                    .onChanged { value in
                        if !isResizing {
                            isResizing = true
                            resizeAnchor = anchor
                            initialBoundingBox = boundingBox
                        }
                        
                        updateBoundingBox(for: anchor, translation: value.translation, fromInitial: initialBoundingBox)
                    }
                    .onEnded { _ in
                        isResizing = false
                    }
            )
    }
    
    private func handleOffset(for anchor: ResizeAnchor, displayX: CGFloat, displayY: CGFloat, displayWidth: CGFloat, displayHeight: CGFloat) -> (CGFloat, CGFloat) {
        switch anchor {
        case .topLeft:
            return (displayX, displayY)
        case .topRight:
            return (displayX + displayWidth, displayY)
        case .bottomLeft:
            return (displayX, displayY + displayHeight)
        case .bottomRight:
            return (displayX + displayWidth, displayY + displayHeight)
        }
    }
    
    private func updateBoundingBox(for anchor: ResizeAnchor, translation: CGSize, fromInitial: NormalizedBoundingBox) {
        let normalizedDeltaX = translation.width / imageGeometry.size.width
        let normalizedDeltaY = -translation.height / imageGeometry.size.height
        
        var newX = fromInitial.x
        var newY = fromInitial.y
        var newWidth = fromInitial.width
        var newHeight = fromInitial.height
        
        let minNormalizedSize: Double = 0.01
        
        switch anchor {
        case .topLeft:
            newX = max(0, fromInitial.x + normalizedDeltaX)
            newY = max(0, fromInitial.y + normalizedDeltaY)
            newWidth = max(minNormalizedSize, fromInitial.width - (newX - fromInitial.x))
            newHeight = max(minNormalizedSize, fromInitial.height - normalizedDeltaY)
            
        case .topRight:
            newY = max(0, fromInitial.y + normalizedDeltaY)
            newWidth = max(minNormalizedSize, fromInitial.width + normalizedDeltaX)
            newHeight = max(minNormalizedSize, fromInitial.height - normalizedDeltaY)
            
        case .bottomLeft:
            newX = max(0, fromInitial.x + normalizedDeltaX)
            newWidth = max(minNormalizedSize, fromInitial.width - (newX - fromInitial.x))
            newHeight = max(minNormalizedSize, fromInitial.height + normalizedDeltaY)
            
        case .bottomRight:
            newWidth = max(minNormalizedSize, fromInitial.width + normalizedDeltaX)
            newHeight = max(minNormalizedSize, fromInitial.height + normalizedDeltaY)
        }
        
        newWidth = min(newWidth, 1 - newX)
        newHeight = min(newHeight, 1 - newY)
        newX = max(0, min(newX, 1 - newWidth))
        newY = max(0, min(newY, 1 - newHeight))
        
        boundingBox = NormalizedBoundingBox(x: newX, y: newY, width: newWidth, height: newHeight)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topLeft = corners.contains(.topLeft) ? radius : 0
        let topRight = corners.contains(.topRight) ? radius : 0
        let bottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let bottomRight = corners.contains(.bottomRight) ? radius : 0
        
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight), radius: topRight, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        path.addArc(center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight), radius: bottomRight, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft), radius: bottomLeft, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addArc(center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft), radius: topLeft, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        
        return path
    }
}
