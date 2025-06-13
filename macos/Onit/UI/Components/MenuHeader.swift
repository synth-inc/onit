//
//  MenuHeader.swift
//  Onit
//
//  Created by Loyd Kim on 4/15/25.
//

import SwiftUI

struct MenuHeader<Child: View>: View {
    private let title: String
    @ViewBuilder private let child: () -> Child
    
    init(
        title: String,
        @ViewBuilder child: @escaping () -> Child
    ) {
        self.title = title
        self.child = child
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .styleText(
                    size: 13,
                    color: .gray100
                )
                .truncateText()
            
            Spacer()
            
            child()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .padding(.horizontal, 16)
    }
}

// Allows `child` prop to be optional.
extension MenuHeader where Child == EmptyView {
    init(title: String) {
        self.init(title: title) { EmptyView() }
    }
}
