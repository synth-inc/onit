//
//  QLImage.swift
//  Onit
//
//  Created by Timothy Lenardo on 2/11/25.
//

import SwiftUI
import Quartz

struct QLImage: NSViewRepresentable {
    
    private let name: String

    init(_ name: String) {
        self.name = name
    }
    
    @State private var hasActivePreview = false
    
    func makeNSView(context: NSViewRepresentableContext<QLImage>) -> QLPreviewView {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif")
        else {
            let _ = print("Cannot get image \(name)")
            return QLPreviewView()
        }
        
        let preview = QLPreviewView(frame: .zero, style: .normal)
        preview?.autostarts = true
        
        // Set initial preview item safely
        DispatchQueue.main.async {
            preview?.previewItem = url as QLPreviewItem
            self.hasActivePreview = true
        }
        
        return preview ?? QLPreviewView()
    }
    
    func updateNSView(_ nsView: QLPreviewView, context: NSViewRepresentableContext<QLImage>) {
        // Only update if the preview is active and the view is still valid
        guard hasActivePreview,
              nsView.window != nil,
              let url = Bundle.main.url(forResource: name, withExtension: "gif") else {
            let _ = print("Cannot get image \(name)")
            return
        }
        
        // Update preview item on main thread
        DispatchQueue.main.async {
            if nsView.window != nil {
                nsView.previewItem = url as QLPreviewItem
            } else {
                print("Cannot set preview item on a closed preview view")
                self.hasActivePreview = false
            }
        }
    }
    
    static func dismantleNSView(_ nsView: QLPreviewView, coordinator: Coordinator) {
        // Clear preview item before dismissal
        DispatchQueue.main.async {
            nsView.previewItem = nil
        }
    }
    
    typealias NSViewType = QLPreviewView
}

struct QLImage_Previews: PreviewProvider {
    static var previews: some View {
        QLImage("preview-gif")
    }
}
