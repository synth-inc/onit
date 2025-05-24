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
    private let showTopBorder: Bool
    private let maxHeight: CGFloat
    private let contentTopPadding: CGFloat
    private let contentRightPadding: CGFloat
    private let contentBottomPadding: CGFloat
    private let contentLeftPadding: CGFloat
    @ViewBuilder private let children: () -> Children
    
    init(
        titleIcon: ImageResource? = nil,
        titleIconColor: Color = Color.white,
        title: String = "",
        showTopBorder: Bool = false,
        maxHeight: CGFloat = 0,
        contentTopPadding: CGFloat = 8,
        contentRightPadding: CGFloat = 8,
        contentBottomPadding: CGFloat = 8,
        contentLeftPadding: CGFloat = 8,
        @ViewBuilder children: @escaping () -> Children
    ) {
        self.titleIcon = titleIcon
        self.titleIconColor = titleIconColor
        self.title = title
        self.showTopBorder = showTopBorder
        self.maxHeight = maxHeight
        self.contentTopPadding = contentTopPadding
        self.contentRightPadding = contentRightPadding
        self.contentBottomPadding = contentBottomPadding
        self.contentLeftPadding = contentLeftPadding
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

// MARK: - Child Components

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
        }
        .padding(.horizontal, 8)
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !title.isEmpty { header }
            children()
        }
        .padding(.init(
            top: contentTopPadding,
            leading: contentLeftPadding,
            bottom: contentBottomPadding,
            trailing: contentRightPadding
        ))
    }
}
