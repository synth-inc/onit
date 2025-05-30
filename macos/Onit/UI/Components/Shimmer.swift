//
//  Shimmer.swift
//  Onit
//
//  Created by Loyd Kim on 5/7/25.
//

import SwiftUI

struct Shimmer: View {
    private let width: CGFloat
    private let height: CGFloat
    private let cornerRadius: CGFloat
    
    init(
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat = 4
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .frame(
                width: width,
                height: height
            )
            .cornerRadius(cornerRadius)
            .fixedShimmer()
    }
}
