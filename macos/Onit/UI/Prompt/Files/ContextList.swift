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
    var onItemTap: ((Context) -> Void)? = nil

    var body: some View {
        if direction == .vertical {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(contextList, id: \.self) { context in
                        ContextItem(item: context, isEditing: false, inList: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .scrollTargetLayout()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onItemTap?(context)
                            }
                    }
                }
                .padding(5)
            }
            .frame(maxHeight: 100, alignment: .top)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.visible)
        } else {
            HStack(spacing: 6) {
                ForEach(contextList, id: \.self) { context in
                    ContextItem(item: context, isEditing: true)
                        .scrollTargetLayout()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onItemTap?(context)
                        }
                }
            }
        }
    }
}

#if DEBUG
    #Preview {
        ContextList(contextList: [])
    }
#endif
