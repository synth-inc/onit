//
//  TypeAheadMenuRowView.swift
//  Onit
//
//  Created by Kévin Naudin on 20/02/2025.
//

import SwiftUI

struct TypeAheadMenuRowView: View {
    let text: String
    let image: ImageResource
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 10) {
                Image(image)
                    .resizable()
                    .frame(width: 14, height: 14)
                Text(text)
                    .appFont(.medium14)
            }
            .padding(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TypeAheadMenuRowView(text: "Delete", image: .bin) {
        
    }
}
