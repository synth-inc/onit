//
//  RemoteModelPicker.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct RemoteModelPicker: View {
    @Environment(\.model) var model

    @State private var aiModel: AIModel = .claude20

    var body: some View {
        Picker("Model", selection: $aiModel) {
            ForEach(AIModel.allCases) { aiModel in
                Text(aiModel.displayName)
                    .tag(aiModel)
            }
        }
        .labelsHidden()
    }
}

struct SelectorMenuStyle: MenuStyle {
    func makeBody(configuration: Configuration) -> some View {

    }
}
