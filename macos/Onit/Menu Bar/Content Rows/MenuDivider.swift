//
//  MenuDivider.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuDivider: View {
    var body: some View {
        DividerHorizontal()
            .padding(.vertical, 4)
            .padding(.horizontal, 9)
    }
}

#Preview {
    MenuDivider()
}
