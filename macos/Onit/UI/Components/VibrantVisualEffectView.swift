//
//  VibrantVisualEffectView.swift
//  Onit
//
//  Created by Kévin Naudin on 06/10/2025.
//

import SwiftUI

struct VibrantVisualEffectView<Content: View>: NSViewRepresentable {
    
    class Coordinator {
        var hostingView: NSHostingView<Content>?
    }
    
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let state: NSVisualEffectView.State
    let content: () -> Content
    
    init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
        self.content = content
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSView(context: Self.Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = state
        
        let hostingView = NSHostingView(rootView: content())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        visualEffectView.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor)
        ])
        
        context.coordinator.hostingView = hostingView
        
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Self.Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        
        if let hostingView = context.coordinator.hostingView {
            hostingView.rootView = content()
        }
    }
}
