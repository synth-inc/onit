//
//  ContextImage.swift
//  Onit
//
//  Created by Kévin Naudin on 28/01/2025.
//

import SwiftUI

struct ContextImage: View {
    var context: Context

    var body: some View {
        switch context {
        case .auto:
            autoContext
        case .image(let url):
            image(url: url)
        case .file:
            file
        case .webSearch(_, _, let source, _):
            webSearchContext(domain: source)
        case .text:
            text
        default:
            warning
        }
    }

    var autoContext: some View {
        Image(.stars)
            .resizable()
            .frame(width: 16, height: 16)
    }

    var file: some View {
        Image(.file)
            .resizable()
            .frame(width: 16, height: 16)
    }

    var imageRect: RoundedRectangle {
        .rect(cornerRadius: 3)
    }

    func image(url: URL) -> some View {
        Color.clear
            .frame(width: 16, height: 16)
            .overlay {
                Image(nsImage: NSImage(byReferencing: url))
                    .resizable()
                    .scaledToFill()
            }
            .imageProgress(url: url)
            .clipShape(imageRect)
            .overlay {
                imageRect
                    .strokeBorder(.gray500)
            }
    }

    func webSearchContext(domain: String) -> some View {
        AsyncImage(url: URL(string: "https://\(domain)/favicon.ico")) { image in
            if let faviconImage = image.image {
                faviconImage
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(2)
            } else {
                Image(systemName: "globe")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(2)
            }
        }
    }
    
    var text: some View {
        Image(.text)
            .addIconStyles(iconSize: 14)
    }
    
    var warning: some View {
        Image(.warning)
            .resizable()
            .frame(width: 16, height: 16)
    }
}
