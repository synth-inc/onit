//
//  RightClickableSwiftUIView.swift
//  Onit
//
//  Created by Kévin Naudin on 06/19/2025.
//

import AppKit
import SwiftUI

struct RightClickableSwiftUIView: NSViewRepresentable {
    
    @Binding var onRightClick: Bool
    
    func updateNSView(_ nsView: RightClickableView, context: Self.Context) {}
    
    func makeNSView(context: Self.Context) -> RightClickableView {
        RightClickableView(onRightClick: $onRightClick)
    }
}

class RightClickableView: NSView {
    
    @Binding var onRightClick: Bool
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    init(onRightClick: Binding<Bool>) {
        _onRightClick = onRightClick
        super.init(frame: NSRect())
    }
    
    override func rightMouseDown(with theEvent: NSEvent) {
        onRightClick.toggle()
    }
}

struct RightClickableModifier: ViewModifier {
    
    @State private var onRightClick = false
    var rightClickCallback: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay {
                RightClickableSwiftUIView(onRightClick: $onRightClick)
                    .onChange(of: onRightClick) { _, _ in
                        self.rightClickCallback()
                    }
            }
    }
}

extension View {
    func rightClickable(_ callback: @escaping () -> Void) -> some View {
        modifier(RightClickableModifier(rightClickCallback: callback))
    }
}
