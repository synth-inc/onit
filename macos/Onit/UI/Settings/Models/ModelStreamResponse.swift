//
//  ModelStreamResponse.swift
//  Onit
//
//  Created by Kévin Naudin on 12/02/2025.
//

import SwiftUI

struct ModelStreamResponse: View {
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text("Use streaming response")
                .foregroundStyle(.primary.opacity(0.65))
                .font(.system(size: 12))
                .fontWeight(.regular)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }
}
