//
//  ScreenHeightModifier.swift
//  Onit
//
//  Created by Kévin Naudin on 18/02/2025.
//

import SwiftUI

struct ScreenHeightModifier: ViewModifier {
    @Binding var screenHeight: CGFloat
//    private let debounceInterval: TimeInterval = 0.1
//    @State private var lastUpdateTime: Date = .now
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            print("ScreenHeightModifier: onAppear")
                            updateFromGeometry(geometry)
                        }
                        .onChange(of: geometry.frame(in: .global)) { _, frame in
                            print("ScreenHeightModifier: onChange frame=\(frame)")
                            
                            let now = Date()
//                            if now.timeIntervalSince(lastUpdateTime) >= debounceInterval {
//                                lastUpdateTime = now
                                updateFromGeometry(geometry)
//                            }
                        }
                }
            )
    }
    
    private func updateFromGeometry(_ geometry: GeometryProxy) {
        let point = convertToScreenCoordinates(geometry.frame(in: .global).origin)
        print("ScreenHeightModifier: converted point=\(point)")
        
        if let window = findWindow(at: point) {
            if let screen = window.screen {
                print("ScreenHeightModifier: found screen frame=\(screen.frame)")
            }
            updateScreenHeight(from: window)
        } else {
            print("ScreenHeightModifier: no window found at point")
        }
    }
    
    private func convertToScreenCoordinates(_ point: CGPoint) -> CGPoint {
        guard let mainScreen = NSScreen.main else { return point }
        
        return CGPoint(
            x: point.x,
            y: mainScreen.frame.height - point.y
        )
    }
    
    private func findWindow(at point: CGPoint) -> NSWindow? {
        for screen in NSScreen.screens {
            if screen.frame.contains(point) {
                return NSApp.windows.first { window in
                    window.screen == screen && window.isVisible
                }
            }
        }
        return nil
    }
    
    private func updateScreenHeight(from window: NSWindow) {
        if let screen = window.screen {
            print("ScreenHeightModifier: updateScreenHeight \(screen.visibleFrame.size.height)")
            DispatchQueue.main.async {
                self.screenHeight = screen.visibleFrame.size.height
            }
        }
    }
}

extension View {
    func screenHeight(binding: Binding<CGFloat>) -> some View {
        self.modifier(ScreenHeightModifier(screenHeight: binding))
    }
}
