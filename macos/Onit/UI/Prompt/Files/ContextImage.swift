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
        if case .loading = context {
            ProgressView()
                .scaleEffect(0.5)
                .frame(width: 12, height: 12)
                .padding(.trailing, 1)
        } else {
            switch context {
            case .webAuto(let appName, _, let metadata):
                Group {
                    if let image = metadata.faviconImage {
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: 16, height: 16)
                            .clipShape(imageRect)
                    } else if appName.starts(with: "Web:") {
                        fallbackGlobeIcon
                    } else {
                        Image(.stars)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .clipShape(imageRect)
                    }
                }
            case .auto(let appName, _):
                if appName.starts(with: "Web:") {
                    fallbackGlobeIcon
                } else {
                    Image(.stars)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .clipShape(imageRect)
                }
            case .image(let url):
                image(url: url)
            case .file:
                file
            default:
                warning
            }
        }
    }

    var fallbackGlobeIcon: some View {
        Image(systemName: "globe")
            .resizable()
            .frame(width: 16, height: 16)
            .clipShape(imageRect)
    }

    var file: some View {
        Image(.file)
            .resizable()
            .frame(width: 20, height: 20)
            .clipShape(imageRect)
    }

    var imageRect: RoundedRectangle {
        .rect(cornerRadius: 3)
    }

    func image(url: URL) -> some View {
        Color.clear
            .frame(width: 20, height: 20)
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

    var warning: some View {
        Image(.warning)
            .resizable()
            .frame(width: 20, height: 20)
            .clipShape(imageRect)
    }
}
