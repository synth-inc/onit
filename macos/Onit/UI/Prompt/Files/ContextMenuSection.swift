//
//  ContextMenuSection.swift
//  Onit
//
//  Created by Loyd Kim on 6/5/25.
//

import SwiftUI

struct ContextMenuSection<Children: View>: View {
    private let showTopBorder: Bool
    private let contentTopPadding: CGFloat
    private let children: Children
    
    init(
        showTopBorder: Bool = false,
        contentTopPadding: CGFloat = 8,
        @ViewBuilder children: @escaping () -> Children
    ) {
        self.showTopBorder = showTopBorder
        self.contentTopPadding = contentTopPadding
        self.children = children()
    }
    
    private let gapSize: CGFloat = 2
    
    private var maxScrollHeight: CGFloat {
        let maxTextButtonCount: CGFloat = 5
        let collectiveTextButtonHeight = ButtonConstants.textButtonHeight * maxTextButtonCount
        
        let gapCount = maxTextButtonCount - 1
        let collectiveGapSize = gapSize * gapCount
        
        let previewHeight: CGFloat = 24
        
        return collectiveTextButtonHeight + collectiveGapSize + previewHeight
    }
    
    var body: some View {
        MenuSection(
            showTopBorder: showTopBorder,
            maxScrollHeight: maxScrollHeight,
            contentTopPadding: contentTopPadding
        ) {
            children
        }
    }
}
