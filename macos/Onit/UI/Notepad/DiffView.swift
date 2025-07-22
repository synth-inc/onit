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
    @State private var viewModel: DiffViewModel
    @State private var currentSegmentRect: CGRect? = nil
    @State private var currentOperationBarSize: CGSize = CGSize(width: 140, height: 30)
    @State private var shouldScrollToSegment: Bool = false
    @State private var isScrolling: Bool = false

    init(response: Response, modelContext: ModelContext) {
        self._viewModel = State(initialValue: DiffViewModel(response: response))
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
                .id("\(viewModel.diffChanges.count)-\(viewModel.isPreviewingAllApproved)")
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
                //insertApprovedChanges()
            } label: {
                Text("Saved")
                    .padding(6)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.FG)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(.T_7)
            )
            .disabled(!viewModel.hasUnsavedChanges)
            
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
    
    // Define operation priority: deletions first, then replacements, then insertions
    private func operationPriority(_ type: String) -> Int {
        switch type {
        case "deleteContentRange": return 0  // Highest priority
        case "replaceText": return 1         // Medium priority  
        case "insertText": return 2          // Lowest priority
        default: return 3                    // Unknown operations last
        }
    }
    
    private func generateDiffSegments() -> [DiffSegment]? {
        guard let arguments = viewModel.diffArguments,
              let result = viewModel.diffResult else { return nil }
        
        let originalText = arguments.original_content
        let operations = result.operations.sorted { (op1, op2) in
            let pos1 = op1.startIndex ?? op1.index ?? 0
            let pos2 = op2.startIndex ?? op2.index ?? 0
            
            if pos1 == pos2 {
                let priority1 = operationPriority(op1.type)
                let priority2 = operationPriority(op2.type)
                return priority1 < priority2
            }
            
            return pos1 < pos2
        }
        
        var segments: [DiffSegment] = []
        var currentPosition = 0
        
        for (opIndex, operation) in operations.enumerated() {
            let operationStart: Int
            
            switch operation.type {
            case "insertText":
                operationStart = operation.index ?? 0
            case "deleteContentRange", "replaceText":
                operationStart = operation.startIndex ?? 0
            default:
                continue
            }
            
            if currentPosition < operationStart {
                let unchangedText = String(originalText[originalText.index(originalText.startIndex, offsetBy: currentPosition)..<originalText.index(originalText.startIndex, offsetBy: operationStart)])
                if !unchangedText.isEmpty {
                    segments.append(DiffSegment(
                        content: unchangedText,
                        type: .unchanged,
                        operationIndex: nil
                    ))
                }
            }
            
            switch operation.type {
            case "insertText":
                if let text = operation.text {
                    segments.append(DiffSegment(
                        content: text,
                        type: .added,
                        operationIndex: opIndex
                    ))
                }
                currentPosition = max(currentPosition, operationStart)
                
            case "deleteContentRange":
                if let endIndex = operation.endIndex {
                    let deletedText = String(originalText[originalText.index(originalText.startIndex, offsetBy: operationStart)..<originalText.index(originalText.startIndex, offsetBy: endIndex)])
                    segments.append(DiffSegment(
                        content: deletedText,
                        type: .removed,
                        operationIndex: opIndex
                    ))
                    currentPosition = endIndex
                }
                
            case "replaceText":
                if let endIndex = operation.endIndex,
                   let newText = operation.newText {
                    let deletedText = String(originalText[originalText.index(originalText.startIndex, offsetBy: operationStart)..<originalText.index(originalText.startIndex, offsetBy: endIndex)])
                    segments.append(DiffSegment(
                        content: deletedText,
                        type: .removed,
                        operationIndex: opIndex
                    ))
                    segments.append(DiffSegment(
                        content: newText,
                        type: .added,
                        operationIndex: opIndex
                    ))
                    currentPosition = endIndex
                }
                
            default:
                break
            }
        }
        
        if currentPosition < originalText.count {
            let remainingText = String(originalText[originalText.index(originalText.startIndex, offsetBy: currentPosition)...])
            if !remainingText.isEmpty {
                segments.append(DiffSegment(
                    content: remainingText,
                    type: .unchanged,
                    operationIndex: nil
                ))
            }
        }
        
        return segments
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
