//
//  Divider.swift
//  Onit
//
//  Created by Loyd Kim on 4/15/25.
//

import SwiftUI

struct DividerHorizontal : View {
    var height: CGFloat = 1
    var foregroundColor: Color = Color.gray700

    var body: some View {
        return Rectangle()
            .frame(height: height)
            .foregroundColor(foregroundColor)
    }
}
