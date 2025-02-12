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
    
    func makeNSView(context: NSViewRepresentableContext<QLImage>) -> QLPreviewView {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif")
        else {
            let _ = print("Cannot get image \(name)")
            return QLPreviewView()
        }
        
        let preview = QLPreviewView(frame: .zero, style: .normal)
        preview?.autostarts = true
        preview?.previewItem = url as QLPreviewItem
        
        return preview ?? QLPreviewView()
    }
    
    func updateNSView(_ nsView: QLPreviewView, context: NSViewRepresentableContext<QLImage>) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif")
        else {
            let _ = print("Cannot get image \(name)")
            return
        }
        nsView.previewItem = url as QLPreviewItem
    }
    
    typealias NSViewType = QLPreviewView
}

struct QLImage_Previews: PreviewProvider {
    static var previews: some View {
        QLImage("preview-gif")
    }
}
