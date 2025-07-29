//
//  DiffView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/07/2025.
//

import KeyboardShortcuts
import SwiftUI
import SwiftData

struct DiffView: View {
	@Environment(\.modelContext) private var modelContext
    @State private var currentSegmentRect: CGRect? = nil
    @State private var currentOperationBarSize: CGSize = CGSize(width: 140, height: 30)
    @State private var shouldScrollToSegment: Bool = false
    @State private var isScrolling: Bool = false
	
	let viewModel: DiffViewModel
    private let response: Response

    init(viewModel: DiffViewModel) {
        self.viewModel = viewModel
        self.response = viewModel.response
    }
    
    var body: some View {
        ZStack {
            if let diffSegments = generateDiffSegments() {
                DiffTextView(
                    segments: diffSegments,
                    currentOperationIndex: viewModel.currentOperationIndex,
                    effectiveChanges: viewModel.getEffectiveDiffChanges(),
                    onSegmentPositionChanged: { rect in
                        currentSegmentRect = rect
                    },
                    onSegmentClicked: { operationIndex in
                        viewModel.currentOperationIndex = operationIndex
                    },
                    shouldScrollToCurrentSegment: shouldScrollToSegment,
                    onScrollStateChanged: { scrolling in
                        isScrolling = scrolling
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id("\(viewModel.response.currentDiffRevisionIndex)-\(viewModel.diffChanges.count)-\(viewModel.isPreviewingAllApproved)")
            }
            
            if viewModel.currentDiffChange?.status == .pending && !isScrolling && !viewModel.isPreviewingAllApproved {
                if let segmentRect = currentSegmentRect {
                    GeometryReader { geometry in
                        VStack {
                            HStack {
                                currentOperationBar
                                	.offset(x: calculateBarXOffset(segmentRect: segmentRect,
                                                                   containerWidth: geometry.size.width,
                                                                   barWidth: currentOperationBarSize.width))
                                Spacer()
                            }
                            .offset(y: segmentRect.minY - currentOperationBarSize.height)
                            Spacer()
                        }
                    }
                }
            }
            
            VStack(alignment: .center, spacing: 8) {
                Spacer()
                
                if !viewModel.diffChanges.filter({ $0.status == .pending }).isEmpty {
                    compactNavigationBar
                }
                
                bottomToolbar
            }
        }
        .background(.BG)
        .background {
            if !viewModel.diffChanges.filter({ $0.status == .pending }).isEmpty {
                upArrowListener
                downArrowListener
                acceptListener
                rejectListener
                insertListener
            }
        }
        .onChange(of: viewModel.currentOperationIndex) { _, _ in
            currentSegmentRect = nil
        }
        .onChange(of: response.isPartial) { oldValue, newValue in
            if oldValue == true && newValue == false {
                viewModel.refreshForResponseUpdate()
            }
        }
        .alert("Insertion Error", isPresented: Binding<Bool>(
            get: { viewModel.insertionError != nil },
            set: { if !$0 { viewModel.clearInsertionError() } }
        )) {
            Button("OK", role: .cancel) {
                viewModel.clearInsertionError()
            }
        } message: {
            Text(viewModel.insertionError ?? "An unknown error occurred")
        }
    }
    
    private func triggerScrollToSegment() {
        shouldScrollToSegment = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            shouldScrollToSegment = false
        }
    }
    
    private var currentOperationBar: some View {
        HStack(spacing: 4) {
            Button {
                viewModel.approveCurrentChange()
            } label: {
                HStack(spacing: 6) {
                    KeyboardShortcutView(shortcut: KeyboardShortcut(KeyEquivalent("y")))
                        .font(.system(size: 13, weight: .medium))
                    Text("Accept")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(.acceptBG)
            )
            
            Button {
                viewModel.rejectCurrentChange()
            } label: {
                HStack(spacing: 6) {
                    KeyboardShortcutView(shortcut: KeyboardShortcut(KeyEquivalent("n")))
                        .font(.system(size: 13, weight: .medium))
                    Text("Reject")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(.rejectBG)
            )
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(.gray700)
                .stroke(.gray500)
        )
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        currentOperationBarSize = geometry.size
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        currentOperationBarSize = newSize
                    }
            }
        )
    }
    
    private var compactNavigationBar: some View {
        HStack(spacing: 2) {
            Button {
                viewModel.approveAllChanges()
            } label: {
                Text("Accept all")
                    .padding(6)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.FG)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(.T_7)
            )
            .onHover { isHovering in
				currentSegmentRect = nil
                if isHovering {
                    viewModel.startPreviewingAllApproved()
                } else {
                    viewModel.stopPreviewingAllApproved()
                }
            }
            
            HStack(spacing: 0) {
                Button(action: {
                    viewModel.navigateToPreviousAvailablePendingChange()
                    triggerScrollToSegment()
                }) {
                    Image(systemName: "chevron.up")
                        .foregroundColor(viewModel.canNavigatePrevious ? .primary : .secondary)
                        .padding(10)
						.contentShape(Rectangle())
                }
                .disabled(!viewModel.canNavigatePrevious)
                .buttonStyle(.plain)
                
                Text("\(viewModel.currentPendingOperationNumber) / \(viewModel.totalPendingOperationsCount)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(minWidth: 30)
                
                Button(action: {
                    viewModel.navigateToNextAvailablePendingChange()
                    triggerScrollToSegment()
                }) {
                    Image(systemName: "chevron.down")
                        .foregroundColor(viewModel.canNavigateNext ? .primary : .secondary)
                        .padding(10)
						.contentShape(Rectangle())
                }
                .disabled(!viewModel.canNavigateNext)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 2)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray700)
                .stroke(.gray500)
        )
    }
    
    private var bottomToolbar: some View {
        HStack {
            Button {
                viewModel.createVariant()
            } label: {
                Text("Create variant")
                    .padding(6)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.FG)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(.T_7)
            )
            
            if viewModel.response.totalDiffRevisions > 1 {
                ToggleDiffVariantView(response: viewModel.response, viewModel: viewModel)
                    .padding(.leading, 8)
            }
            
            Spacer()
            
            CopyButton(text: viewModel.generatePreviewText())
            
            Button {
                viewModel.insert()
            } label: {
                HStack(spacing: 6) {
                    let text = viewModel.diffArguments?.document_url != nil ? "Update" : "Insert"
                    
                    Text(text)
                    
                    if viewModel.isInserting {
                        Loader(size: 14, scaleEffect: 0.5)
                    } else {
                        KeyboardShortcutView(shortcut: KeyboardShortcut(.return))
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                            .background(.blue300, in: .rect(cornerRadius: 5))
                    }
                }
                .padding(6)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.FG)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(.blue400)
            )
            .disabled(!viewModel.hasUnsavedChanges || viewModel.isInserting)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray700)
                .stroke(.gray600)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
    private func generateDiffSegments() -> [DiffSegment]? {
        guard let arguments = viewModel.diffArguments,
              let result = viewModel.diffResult else { return nil }
        
        return DiffSegmentUtils.generateDiffSegments(
            originalText: arguments.original_content,
            operations: result.operations
        )
    }
    
    private func calculateBarXOffset(segmentRect: CGRect, containerWidth: CGFloat, barWidth: CGFloat) -> CGFloat {
        let desiredXOffset = segmentRect.minX
        let minXOffset: CGFloat = 0
        let maxXOffset = max(0, containerWidth - barWidth)
        
        return max(minXOffset, min(maxXOffset, desiredXOffset))
    }
}

// MARK: - Keyboard Listeners

extension DiffView {
    private var upArrowListener: some View {
        KeyListener(key: .upArrow, modifiers: []) {
            viewModel.navigateToPreviousAvailablePendingChange()
            triggerScrollToSegment()
        }
    }
    
    private var downArrowListener: some View {
        KeyListener(key: .downArrow, modifiers: []) {
            viewModel.navigateToNextAvailablePendingChange()
            triggerScrollToSegment()
        }
    }
    
    private var acceptListener: some View {
        KeyListener(key: KeyEquivalent("y"), modifiers: [.command]) {
            viewModel.approveCurrentChange()
        }
    }
    
    private var rejectListener: some View {
        KeyListener(key: KeyEquivalent("n"), modifiers: [.command]) {
            viewModel.rejectCurrentChange()
        }
    }
    
    private var insertListener: some View {
        KeyListener(key: .return, modifiers: [.command]) {
            viewModel.insert()
        }
    }
}

// MARK: - DiffSegment Model

struct DiffSegment {
    let content: String
    let type: DiffSegmentType
    let operationIndex: Int?
}

enum DiffSegmentType {
    case unchanged
    case added
    case removed
}
