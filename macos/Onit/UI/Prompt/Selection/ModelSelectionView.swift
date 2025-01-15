//
//  ModelSelectionView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import SwiftUI

struct ModelSelectionView: View {
    @Environment(\.model) var model

    var body: some View {
        VStack(spacing: 0) {
            remote
            divider
            local
            divider
//            advanced
        }
        .foregroundStyle(.FG)
        .padding(.vertical, 12)
        .background(.gray600, in: .rect(cornerRadius: 12))
        .frame(minWidth: 218, alignment: .leading)
    }

    var remote: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Remote models")
                    .appFont(.medium13)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Image(.warningSettings)
            }
            .padding(.horizontal, 12)

            remoteModels
        }
    }

    var remoteModels: some View {
        Picker("", selection: model.selectedModel) {
            ForEach(model.preferences.visibleModelsList) { model in
                Text(model.displayName)
                    .appFont(.medium14)
                    .tag(SelectedModel.remote(model))
                    .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pickerStyle(.inline)
        .padding(.vertical, 4)
        .padding(.bottom, 5)
        .padding(.leading, 5)
        .tint(.blue600)
    }

    var divider: some View {
        Color.gray400
            .frame(height: 1)
    }

    var local: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Text("Local models")
                    .foregroundStyle(.FG.opacity(0.6))
                    .appFont(.medium13)
                Image(.warningSettings)
                Spacer()
                add
            }
            .padding(.horizontal, 12)

            localModels
        }
        .padding(.vertical, 8)
    }

    var localModels: some View {
        Picker("", selection: model.selectedModel) {
            ForEach(model.availableLocalModels, id: \.self) { localModelName in
                Text(localModelName)
                    .appFont(.medium14)
                    .tag(SelectedModel.local(localModelName))
                    .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pickerStyle(.inline)
        .padding(.vertical, 4)
        .padding(.bottom, 5)
        .padding(.leading, 5)
        .tint(.blue600)
    }

    var add: some View {
        HStack(spacing: 4) {
            Text("Add")
                .appFont(.medium13)
            Image(.plus)
        }
        .padding(.vertical, 2)
        .padding(.leading, 4)
        .padding(.trailing, 4)
        .background(.gray400, in: .rect(cornerRadius: 5))
        .opacity(0.3)
    }
//
//    var advanced: some View {
//
//    }
}

#Preview {
    ModelSelectionView()
}
