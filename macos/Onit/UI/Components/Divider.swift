//
//  Divider.swift
//  Onit
//
//  Created by Loyd Kim on 4/15/25.
//

import SwiftUI

func DividerHorizontal(
    height: CGFloat = 1,
    foregroundColor: Color = Color.gray700
) -> some View {
    return Rectangle()
        .frame(height: height)
        .foregroundColor(foregroundColor)
}
