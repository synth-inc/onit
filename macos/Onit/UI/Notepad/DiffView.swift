//
//  DiffView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/07/2025.
//

import SwiftUI
import SwiftData

struct DiffView: View {
    @State private var viewModel: DiffViewModel
    @Environment(\.modelContext) private var modelContext

	private func attributedText(for segments: [DiffSegment]) -> AttributedString {
        var result = AttributedString()
        let effectiveChanges = viewModel.getEffectiveDiffChanges()
        

        
        for segment in segments {
            var segmentText = AttributedString(segment.content)
            
            let segmentStatus: DiffChangeStatus? = {
                guard let opIndex = segment.operationIndex else { return nil }
				
                return effectiveChanges.first { $0.operationIndex == opIndex }?.status
            }()
            
            switch segment.type {
            case .unchanged:
                segmentText.foregroundColor = .primary
                
            case .added:
				switch segmentStatus {
				case .approved:
					segmentText.foregroundColor = .primary
				case .pending:
					segmentText.foregroundColor = .green
					segmentText.backgroundColor = Color.green.opacity(0.2)
				case .rejected:
					continue
				default:
					segmentText.foregroundColor = .gray
					segmentText.backgroundColor = Color.gray.opacity(0.1)
				}
                
            case .removed:
				switch segmentStatus {
				case .approved:
					continue
				case .pending:
					segmentText.foregroundColor = .red
					segmentText.backgroundColor = Color.red.opacity(0.2)
					segmentText.strikethroughStyle = .single
				case .rejected:
					segmentText.foregroundColor = .primary
				default:
					segmentText.foregroundColor = .gray
					segmentText.backgroundColor = Color.gray.opacity(0.1)
					segmentText.strikethroughStyle = .single
				}
            }
            
            if let opIndex = segment.operationIndex, opIndex == viewModel.currentOperationIndex {
                segmentText.backgroundColor = Color.accentColor.opacity(0.3)
            }
            
            result.append(segmentText)
        }
        
        return result
    }
    
    init(response: Response, modelContext: ModelContext) {
        self._viewModel = State(initialValue: DiffViewModel(response: response, modelContext: modelContext))
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                if let diffSegments = generateDiffSegments() {
                    Text(attributedText(for: diffSegments))
           				.font(.system(size: 14).monospaced())
            			.frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .id(viewModel.isPreviewingAllApproved)
                }
            }
            
            VStack(alignment: .center, spacing: 8) {
                Spacer()
                
                //if viewModel.statistics.pending > 0 {
                    compactNavigationBar
                //}
                
                bottomToolbar
            }
        }
        .background(.BG)
    }
    
    private var compactNavigationBar: some View {
        HStack(spacing: 12) {
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
                if isHovering {
                    viewModel.startPreviewingAllApproved()
                } else {
                    viewModel.stopPreviewingAllApproved()
                }
            }
            
            HStack(spacing: 8) {
                Button(action: viewModel.navigatePrevious) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.canNavigatePrevious ? .primary : .secondary)
                }
                .disabled(!viewModel.canNavigatePrevious)
                .buttonStyle(.plain)
                
                Text("\(viewModel.currentOperationIndex + 1) / \(viewModel.diffResult?.operations.count ?? 0)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(minWidth: 30)
                
                Button(action: viewModel.navigateNext) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.canNavigateNext ? .primary : .secondary)
                }
                .disabled(!viewModel.canNavigateNext)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
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
                insertApprovedChanges()
            } label: {
                Text("Saved")
                    .padding(6)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.FG)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(.T_7)
            )
            .disabled(!viewModel.hasUnsavedChanges)
            
            Spacer()
            
            CopyButton(text: viewModel.generatePreviewText())
            
            Button {
                insertApprovedChanges()
            } label: {
                Text("Insert")
                    .padding(6)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.FG)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(.blue400)
            )
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
    
    private func insertApprovedChanges() {
        let previewText = viewModel.generatePreviewText()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(previewText, forType: .string)
        
        viewModel.markAsSaved()
        
        // TODO: Show confirmation or handle insertion based on the source application
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

