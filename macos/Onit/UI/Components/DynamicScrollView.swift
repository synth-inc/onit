//
//  DynamicScrollView.swift
//  Onit
//
//  Created by Loyd Kim on 6/4/25.
//

import SwiftUI

struct DynamicScrollView<Children: View>: View {
    private let maxHeight: CGFloat
    private let gradientColor: Color
    @ViewBuilder private let children: () -> Children
    
    init(
        maxHeight: CGFloat,
        gradientColor: Color = .gray900,
        @ViewBuilder children: @escaping () -> Children
    ) {
        self.maxHeight = maxHeight
        self.gradientColor = gradientColor
        self.children = children
    }
    
    @State private var childrenHeight: CGFloat = 0
    @State private var maxScrollHeight: CGFloat = 0
    @State private var yScrollPosition: CGFloat = 0
    
    private let scrollOffset: CGFloat = 5
    
    private var showTopGradient: Bool {
        let notScrolledToTop = yScrollPosition > scrollOffset
        return notScrolledToTop
    }
    
    private var showBottomGradient: Bool {
        let currentMaxScrollHeight = max(0, childrenHeight - maxScrollHeight)
        let notScrolledToBottom = yScrollPosition < currentMaxScrollHeight - scrollOffset
        return notScrolledToBottom
    }
    
    let coordinateSpaceName = "dynamicScrollViewComponent"
    let gradientHeight: CGFloat = 40
    
    var body: some View {
        ScrollView {
            children()
                .background {
                    // Required for scroll view dynamic max height.
                    GeometryReader { proxy in
                        let yOffset = proxy.frame(in: .named(coordinateSpaceName)).minY
                        
                        Color.clear
                            .onAppear {
                                childrenHeight = proxy.size.height
                            }
                            .onChange(of: proxy.size.height) { _, newHeight in
                                childrenHeight = newHeight
                            }
                            .onChange(of: yOffset) { _, newYOffset in
                                yScrollPosition = -newYOffset
                            }
                    }
                }
        }
        .coordinateSpace(name: coordinateSpaceName)
        .background(
            // Required to display bottom gradient.
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        maxScrollHeight = proxy.size.height
                    }
                    .onChange(of: proxy.size.height) { _, newHeight in
                        maxScrollHeight = newHeight
                    }
            }
        )
        .frame(alignment: .leading)
        .frame(maxHeight: childrenHeight == 0 ? maxHeight : min(childrenHeight, maxHeight))
        .overlay(topGradient)
        .overlay(bottomGradient)
    }
}

// MARK: - Child Components

extension DynamicScrollView {
    private var topGradient: some View {
        VStack(spacing: 0) {
            if showTopGradient {
                LinearGradient(
                    gradient: Gradient(colors: [gradientColor, Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: gradientHeight)
            }
            
            Spacer()
        }
        .allowsHitTesting(false)
    }
    
    private var bottomGradient: some View {
        VStack(spacing: 0) {
            Spacer()
            
            if showBottomGradient {
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, gradientColor]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: gradientHeight)
            }
        }
        .allowsHitTesting(false)
    }
}
