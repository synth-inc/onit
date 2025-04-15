//
//  MenuSection.swift
//  Onit
//
//  Created by Loyd Kim on 4/15/25.
//

import SwiftUI

struct MenuSection<Children: View>: View {
    private let titleIcon: ImageResource?
    private let titleIconColor: Color
    private let title: String
    private let titleChild: (any View)?
    private let showTopBorder: Bool
    private let maxHeight: CGFloat
    @ViewBuilder private let children: () -> Children
    
    init(
        titleIcon: ImageResource? = nil,
        titleIconColor: Color = Color.white,
        title: String = "",
        titleChild: (any View)? = nil,
        showTopBorder: Bool = false,
        maxHeight: CGFloat = 0,
        @ViewBuilder children: @escaping () -> Children
    ) {
        self.titleIcon = titleIcon
        self.titleIconColor = titleIconColor
        self.title = title
        self.titleChild = titleChild
        self.showTopBorder = showTopBorder
        self.maxHeight = maxHeight
        self.children = children
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if maxHeight > 0 || showTopBorder { DividerHorizontal() }
            
            if maxHeight > 0 {
                ScrollView { content }.frame(maxHeight: maxHeight)
            } else {
                content
            }
        }
    }
}

/// Child Components
extension MenuSection {
    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(alignment: .center, spacing: 4) {
                if let titleIcon = titleIcon {
                    Image(titleIcon).addIconStyles(
                        foregroundColor: titleIconColor,
                        iconSize: 16
                    )
                }
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.gray100)
                    .truncateText()
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
            
            if let titleChild = titleChild {
                Spacer()
                AnyView(titleChild)
            }
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !title.isEmpty { header }
            children()
        }
        .padding(8)
    }
}
