//
//  SizeCalculatorModifier.swift
//  Onit
//
//  Created by Kévin Naudin on 10/02/2025.
//

import SwiftUI

struct SizeCalculatorModifier: ViewModifier {
    
    @Binding var size: CGSize
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.size, initial: true) { _, new in
                            size = new
                        }
                }
            )
    }
}

extension View {
    func saveSize(in size: Binding<CGSize>) -> some View {
        modifier(SizeCalculatorModifier(size: size))
    }
}
