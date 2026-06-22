//
//  Backgrounds.swift
//  Onit
//
//  Created by Loyd Kim on 7/29/25.
//

import SwiftUI

struct GlassBackground: View {
    var body: some View {
        Rectangle()
            .fill(.thinMaterial)
            .opacity(0.5)
    }
}

struct Backgrounds {
    struct BrushedGlass: NSViewRepresentable {
        private func setVisualEffectView(_ visualEffectView: NSVisualEffectView) {
            visualEffectView.material = .hudWindow /// Set macOS HUD material as the window background.
            visualEffectView.blendingMode = .behindWindow /// Ensure see-through, blending effect.
            visualEffectView.state = .active /// Persist glass-like appearance.
        }
        
        func makeNSView(context: Self.Context) -> NSVisualEffectView {
            let visualEffectView = NSVisualEffectView()
            setVisualEffectView(visualEffectView)
            return visualEffectView
        }
        
        func updateNSView(_ visualEffectView: NSVisualEffectView, context: Self.Context) {
            setVisualEffectView(visualEffectView)
        }
    }
}
