//
//  ContextList.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct ContextList: View {

    var contextList: [Context]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(contextList, id: \.self) { context in
                    ContextItem(item: context)
                        .scrollTargetLayout()
                }
            }
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        ContextList(contextList: [])
    }
}
#endif
