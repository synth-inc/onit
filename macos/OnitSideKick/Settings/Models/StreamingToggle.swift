//
//  ModelStreamResponse.swift
//  Onit
//
//  Created by Kévin Naudin on 12/02/2025.
//

import SwiftUI

struct StreamingToggle: View {
    @Binding var isOn: Bool
    @State private var showInfo: Bool = false

    var body: some View {
        HStack {
            Toggle(isOn: $isOn) {
                Text(String.localized("Stream responses", table: "Models"))
                    .font(.system(size: 12))
                    .fontWeight(.regular)
                    .foregroundStyle(Color.S_0.opacity(0.65))
            }

            Button(action: {
                showInfo.toggle()
            }) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.S_0.opacity(0.65))
                    .font(.system(size: 12))
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showInfo) {
                Text(String.localized("If enabled, Onit streams partial responses from model providers, offering quicker replies. This may not function with all providers.", table: "Models"))
                    .padding(12)
                    .frame(width: 200)
                    .foregroundColor(Color.S_0)
            }
            
            Spacer()
        }
    }
}
