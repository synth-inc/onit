//
//  Divider.swift
//  Onit
//
//  Created by Loyd Kim on 4/15/25.
//

import SwiftUI

struct DividerHorizontal : View {
    var height: CGFloat = 1
    var width: CGFloat? = nil
    var foregroundColor: Color = Color.genericBorder

    var body: some View {
        return Rectangle()
            .frame(
                width: width,
                height: height
            )
            .foregroundColor(foregroundColor)
    }
}
