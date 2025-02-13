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
    
    var additionalInfo: String?

    var body: some View {
        HStack {
            Toggle(isOn: $isOn) {
                Text("Stream responses")
                    .font(.system(size: 12))
                    .fontWeight(.regular)
                    .foregroundStyle(.primary.opacity(0.65))
            }
            .toggleStyle(.checkbox)
            
            Button(action: {
                showInfo.toggle()
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 12))
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showInfo) {
                Text(additionalInfo ?? "If enabled, Onit streams partial responses from model providers, offering quicker replies. This may not function with all providers.")
                    .padding()
                    .frame(width: 200)
            }
            
            Spacer()
        }
    }
}
