//
//  DeleteModelsView.swift
//  Onit
//
//  Created by Loyd Kim on 3/14/25.
//

import SwiftUI
import Defaults

struct DeleteModelsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.model) var model

    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            title
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(model.modelsByProvider, id: \.0) { provider, models in
                        if !models.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(provider.title).font(.system(size: 14, weight: .bold))
                                
                                ForEach(models) { model in
                                    DeleteModelsViewSelectionRow(aiModel: model)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } 
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }

            VStack(spacing: 0) {
                divider
                
                HStack {
                    cancelButton
                    deleteButton
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
        }
        .frame(width: 330, height: 400)
        .confirmationDialog(
            model.modelIdsSelectedForDeletion.count > 1 ?
                "Are you sure you want to delete the selected models?" :
                "Are you sure you want to delete the selected model?",
            isPresented: $showDeleteConfirmation
        ) {
            confirmDeleteButton
            confirmCancelButton
        }
    }
}

extension DeleteModelsView {
    var divider: some View {
        Rectangle()
            .frame(height:1)
            .foregroundColor(.gray.opacity(0.2))
    }
    
    var title: some View {
        VStack(spacing: 0) {
            Text("Delete Models")
                .font(.system(size:16))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            
            divider
        }
        .frame(alignment: .center)
    }
    
    var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
        .buttonStyle(.borderedProminent)
        .tint(.secondary)
        .controlSize(.small)
    }
    
    var deleteButton: some View {
        Button("Delete") {
            showDeleteConfirmation = true
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .disabled(model.modelIdsSelectedForDeletion.isEmpty)
    }
    
    var confirmDeleteButton: some View {
        Button("Delete", role: .destructive) {
            model.deleteSelectedModels(
                dismiss: { dismiss() }
            )
        }
    }
    
    var confirmCancelButton: some View {
        Button("Cancel", role: .cancel) {}
    }
}
