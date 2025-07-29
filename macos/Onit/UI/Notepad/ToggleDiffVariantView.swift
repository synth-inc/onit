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
        let sortedRevisions = response.sortedDiffRevisions

        guard let currentPosition = sortedRevisions.firstIndex(where: { 
			$0.index == response.currentDiffRevisionIndex
		}) else { return false }
		
        return currentPosition > 0
    }
    
    private var canIncrementRevision: Bool {
        let sortedRevisions = response.sortedDiffRevisions

        guard let currentPosition = sortedRevisions.firstIndex(where: { 
			$0.index == response.currentDiffRevisionIndex
		}) else { return false }
		
        return currentPosition < sortedRevisions.count - 1
    }
}

// MARK: - Private Functions

extension ToggleDiffVariantView {
    private func decrementRevisionIndex() {
        if canDecrementRevision {
            let sortedRevisions = response.sortedDiffRevisions

            guard let currentPosition = sortedRevisions.firstIndex(where: { 
				$0.index == response.currentDiffRevisionIndex 
			}), currentPosition > 0 else { return }
            
            let previousRevision = sortedRevisions[currentPosition - 1]
			
            response.setCurrentRevision(index: previousRevision.index)
            viewModel.refreshForRevisionChange()
        }
    }
    
    private func incrementRevisionIndex() {
        if canIncrementRevision {
            let sortedRevisions = response.sortedDiffRevisions

            guard let currentPosition = sortedRevisions.firstIndex(where: { 
				$0.index == response.currentDiffRevisionIndex
			}), currentPosition < sortedRevisions.count - 1 else { return }
            
            let nextRevision = sortedRevisions[currentPosition + 1]
			
            response.setCurrentRevision(index: nextRevision.index)
            viewModel.refreshForRevisionChange()
        }
    }
}
