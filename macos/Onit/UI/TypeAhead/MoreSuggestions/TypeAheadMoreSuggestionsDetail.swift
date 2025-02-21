//
//  TypeAheadMoreSuggestionsDetail.swift
//  Onit
//
//  Created by Kévin Naudin on 21/02/2025.
//

import SwiftUI

struct TypeAheadMoreSuggestionsDetail: View {
    let text: String
    @State private var contentHeight: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("more...")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.gray200)
            
            ScrollView {
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.gray100)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    contentHeight = proxy.size.height
                                }
                                .onChange(of: proxy.size.height) { _, newValue in
                                    contentHeight = newValue
                                }
                        }
                    )
            }
            .frame(maxWidth: 300)
            .frame(height: min(contentHeight, 200))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

#Preview {
    TypeAheadMoreSuggestionsDetail(text: "An example")
}
