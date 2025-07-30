//
//  NotepadView.swift
//  Onit
//
//  Created by Kévin Naudin on 13/03/2025.
//

import SwiftUI
import SwiftData

struct NotepadView: View {
    static let toolbarHeight: CGFloat = 32
    
    let response: Response
    let closeCompletion: (() -> Void)
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DiffViewModel
    
    init(response: Response, closeCompletion: @escaping () -> Void) {
        self.response = response
        self.closeCompletion = closeCompletion
        self._viewModel = State(initialValue: DiffViewModel(response: response))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            PromptDivider()
            DiffView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    private var toolbar: some View {
        HStack {
            close
            Spacer()
            
        }
        .frame(height: Self.toolbarHeight)
    }
    
    private var close: some View {
        Button(action: {
            // viewModel.createVariant()
            closeCompletion()
        }) {
            Image(.smallCross)
                .frame(width: 48, height: 32)
                .foregroundStyle(.gray200)
        }
        .buttonStyle(.plain)
    }
}
