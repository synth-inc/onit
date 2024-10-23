//
//  ContextList.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct ContextList: View {
    @Environment(\.model) var model

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(model.context, id: \.self) { context in
                    ContextItem(item: context)
                        .scrollTargetLayout()
                }
            }
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
    }
}

#Preview {
    ContextList()
        .environment(OnitModel())
}
