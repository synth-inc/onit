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
        .shadow(color: .BG.opacity(0.36), radius: 5)
    }

    var remote: some View {
        VStack(spacing: 2) {
            HStack {
                Text("Remote models")
                    .appFont(.medium13)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Image(.warningSettings)
            }
            remoteModels
        }
        .padding(.horizontal, 12)
    }

    var modelBinding: Binding<AIModel> {
        .init {
            .chatgpt4oLatest
        } set: { value in

        }
    }

    var remoteModels: some View {
        Picker("", selection: modelBinding) {
            ForEach(model.preferences.visibleModelsList) { model in

            }
        }
        .pickerStyle(.inline)
    }

    var divider: some View {
        Color.gray400
            .frame(height: 1)
    }

    var local: some View {
        VStack(spacing: 2) {
            HStack {
                Text("Local models")
                    .foregroundStyle(.FG.opacity(0.6))
                    .appFont(.medium13)
                Image(.warningSettings)
                Spacer()
                add
            }
            .padding(.horizontal, 6)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
    }

    var add: some View {
        HStack(spacing: 0) {
            Text("Add")
                .appFont(.medium13)
            Image(.plus)
        }
        .padding(.vertical, 1)
        .padding(.leading, 4)
        .padding(.trailing, 1)
        .background(.gray400, in: .rect(cornerRadius: 5))
    }
//
//    var advanced: some View {
//
//    }
}

#Preview {
    ModelSelectionView()
}
