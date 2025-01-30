//
//  ContextList.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct ContextList: View {

    var contextList: [Context]
    var direction: Axis.Set = .horizontal

    var body: some View {
        if direction == .vertical {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(contextList, id: \.self) { context in
                        ContextItem(item: context, isEditing: false)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .scrollTargetLayout()
                    }
                }
                .padding(5)
            }
            .frame(maxHeight: 100, alignment: .top)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.visible)
        } else {
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(contextList, id: \.self) { context in
                        ContextItem(item: context, isEditing: true)
                            .scrollTargetLayout()
                    }
                }
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
        }
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        ContextList(contextList: [])
    }
}
#endif
