//
//  ContextPickerView.swift
//  Onit
//
//  Created by Kévin Naudin on 25/01/2025.
//

import SwiftUI

struct ContextPickerView: View {
    @Environment(\.model) var model
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: {
                model.closeContextPickerOverlay()
                model.showFileImporter = true
            }) {
                ContextPickerItemView(imageRes: .file, title: "Upload file", subtitle: "Choose from computer")
            }
            .padding(.top, 6)
            .buttonStyle(.plain)
            
            Button(action: {
                model.closeContextPickerOverlay()
                model.addAutoContext()
            }) {
                ContextPickerItemView(imageRes: .stars, title: "Auto-context", subtitle: "Current window activity")
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
        }
        .background(Color(.gray600))
        .cornerRadius(12)
    }
}
