//
//  FloatingPanelModifier.swift
//  Onit
//
//  Created by Benjamin Sage on 9/30/24.
//

import SwiftUI

fileprivate struct FloatingPanelModifier<PanelContent: View>: ViewModifier {
    @Binding var isPresented: Bool

    var contentRect: CGRect = CGRect(x: 0, y: 0, width: 624, height: 512)

    @ViewBuilder let view: () -> PanelContent

    @State var panel: FloatingPanel<PanelContent>?

    func body(content: Content) -> some View {
        content
            .onAppear {
                panel = FloatingPanel(view: view, contentRect: contentRect, isPresented: $isPresented)
                panel?.center()
                if isPresented {
                    present()
                }
            }
            .onDisappear {
                panel?.close()
                panel = nil
            }
            .onChange(of: isPresented) {
                print(isPresented)
                if isPresented {
                    present()
                } else {
                    panel?.close()
                }
            }
    }

    func present() {
        panel?.makeKeyAndOrderFront(panel)
    }
}

extension View {
    func floatingPanel<Content: View>(
        isPresented: Binding<Bool>,
        contentRect: CGRect = CGRect(x: 0, y: 0, width: 624, height: 512),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(FloatingPanelModifier(isPresented: isPresented, contentRect: contentRect, view: content))
    }
}
