//
//  MenuList.swift
//  Onit
//
//  Created by Loyd Kim on 4/14/25.
//

import SwiftUI

struct MenuList<Sections: View>: View {
    let header: (any View)?
    let width: CGFloat
    @ViewBuilder private let sections: () -> Sections
    
    struct Search {
        @Binding var query: String
        var placeholder: String = "Search for..."
    }
    let search: Search?
    
    init(
        header: (any View)? = nil,
        width: CGFloat = 320,
        search: Search? = nil,
        @ViewBuilder sections: @escaping () -> Sections
    ) {
        self.header = header
        self.width = width
        self.search = search
        self.sections = sections
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let header = header { AnyView(header) }
            
            if let search = search {
                SearchBar(
                    searchQuery: search.$query,
                    placeholder: search.placeholder,
                    sidePadding: 8
                )
                .padding(.bottom, 8)
            }
            
            sections()
        }
        .background(.gray900)
        .frame(width: width)
        .addBorderRadius()
        .addShadow()
    }
}
