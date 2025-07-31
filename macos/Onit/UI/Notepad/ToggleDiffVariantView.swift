//
//  ToggleDiffVariantView.swift
//  Onit
//
//  Created by Kévin Naudin on 29/07/2025.
//

import SwiftUI

struct ToggleDiffVariantView: View {
    @Environment(\.windowState) var windowState
    
    let response: Response
    let viewModel: DiffViewModel
    
    private var currentPosition: Int? {
        let sortedRevisions = response.sortedDiffRevisions
        
        return sortedRevisions.firstIndex(where: {
            $0.index == response.currentDiffRevisionIndex
        })
    }
    
    var body: some View {
        HStack(spacing: 0) {
            `left`
            text
            `right`
        }
        .buttonStyle(.plain)
        .foregroundStyle(.gray300)
    }

    var left: some View {
        Button {
            decrementRevisionIndex()
        } label: {
            Color.clear
                .frame(width: 20, height: 20)
                .overlay {
                    Image(.chevLeft)
                }
        }
        .foregroundStyle(canDecrementRevision ? .FG : .gray300)
        .disabled(!canDecrementRevision)
    }

    @ViewBuilder
    var text: some View {
        if response.totalDiffRevisions > 1 {
            let sortedRevisions = response.sortedDiffRevisions
            let currentPosition = sortedRevisions.firstIndex { $0.index == response.currentDiffRevisionIndex } ?? 0
            Text("\(currentPosition + 1) / \(response.totalDiffRevisions)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.FG)
        }
    }

    var right: some View {
        Button {
            incrementRevisionIndex()
        } label: {
            Color.clear
                .frame(width: 20, height: 20)
                .overlay {
                    Image(.chevRight)
                }
        }
        .foregroundStyle(canIncrementRevision ? .FG : .gray300)
        .disabled(!canIncrementRevision)
    }
    
    // MARK: - Computed Properties
    
    private var canDecrementRevision: Bool {
        guard let currentPosition = currentPosition else { return false }
		
        return currentPosition > 0
    }
    
    private var canIncrementRevision: Bool {
        guard let currentPosition = currentPosition else { return false }
        
        let sortedRevisions = response.sortedDiffRevisions
		
        return currentPosition < sortedRevisions.count - 1
    }
}

// MARK: - Private Functions

extension ToggleDiffVariantView {
    private func decrementRevisionIndex() {
        if canDecrementRevision {
            guard let currentPosition = currentPosition, currentPosition > 0 else { return }
            
            let sortedRevisions = response.sortedDiffRevisions
            let previousRevision = sortedRevisions[currentPosition - 1]
			
            response.setCurrentRevision(index: previousRevision.index)
            viewModel.refreshForRevisionChange()
        }
    }
    
    private func incrementRevisionIndex() {
        if canIncrementRevision {
            let sortedRevisions = response.sortedDiffRevisions
            
            guard let currentPosition = currentPosition,
                  currentPosition < sortedRevisions.count - 1 else { return }
            
            let nextRevision = sortedRevisions[currentPosition + 1]
			
            response.setCurrentRevision(index: nextRevision.index)
            viewModel.refreshForRevisionChange()
        }
    }
}
