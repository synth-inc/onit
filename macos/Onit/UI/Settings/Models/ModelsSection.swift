//
//  ModelsSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct ModelsSection<Content: View>: View {
    var title: String
    @Environment(\.appState) var appState
    @State private var fetching: Bool = false
    
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(title)
                    .font(.system(size: 14))
                Spacer()
                Button(action: {
                    fetching = true
                    Task {
                        await appState?.fetchRemoteModels()
                        fetching = false
                    }
                }) {
                    if fetching {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Refresh")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(fetching)
            }
            content()
        }
        .fontWeight(.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ModelsSection(title: "Local") {
        TextField("Text here", text: .constant(""))
    }
}
