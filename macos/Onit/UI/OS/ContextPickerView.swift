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
                ContextView(imageRes: .file, title: "Upload file", subtitle: "Choose from computer")
            }
            .padding(.top, 6)
            .buttonStyle(.plain)
            
            Button(action: {
                model.closeContextPickerOverlay()
                model.addAutoContext()
            }) {
                ContextView(imageRes: .stars, title: "Auto-context", subtitle: "Current window activity")
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
        }
        .background(Color(.gray600))
        .cornerRadius(12)
    }
}

struct ContextView: View {
    
    let imageRes: ImageResource
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 0) {
            Image(imageRes)
                .resizable()
                .frame(width: 20, height: 20)
                .padding(.leading, 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appFont(.medium14)
                    .foregroundColor(.white)
                Text(subtitle)
                    .appFont(.medium13)
                    .foregroundColor(.gray200)
            }
            .padding(.leading, 8)
            .padding(.vertical, 6)
        }
        .frame(minWidth: 210, alignment: .leading)
    }
}

#Preview {
    ContextPickerView()
}
