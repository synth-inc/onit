//
//  DefaultModelsSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct DefaultModelsSection: View {
    var body: some View {
        ModelsSection(title: String.localized("Default models", table: "Models")) {
            VStack(alignment: .leading, spacing: 8) {
                remote
                DividerHorizontal()
                local
            }
        }
    }

    var remote: some View {
        HStack {
            Text(String.localized("Remote", table: "Models"))
            Spacer()
            RemoteModelPicker()
        }
    }

    var local: some View {
        HStack {
            Text(String.localized("Local", table: "Models"))
            Spacer()
            LocalModelPicker()
        }
    }
}

#Preview {
    DefaultModelsSection()
}
