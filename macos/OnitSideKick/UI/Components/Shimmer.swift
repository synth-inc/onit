//
//  Shimmer.swift
//  Onit
//
//  Created by Loyd Kim on 5/7/25.
//

import SwiftUI

struct Shimmer: View {
    private let width: CGFloat?
    private let height: CGFloat?
    private let cornerRadius: CGFloat
    private let fillContainer: Bool
    
    init(
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        cornerRadius: CGFloat = 4,
        fillContainer: Bool = false
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.fillContainer = fillContainer
    }
    
    var body: some View {
        Rectangle()
            .frame(
                width: width,
                height: height
            )
            .frame(maxWidth: fillContainer ? .infinity : nil)
            .cornerRadius(cornerRadius)
            .shimmering()
    }
}
