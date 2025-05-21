//
//  ContextPickerItemView.swift
//  Onit
//
//  Created by Kévin Naudin on 28/01/2025.
//

import SwiftUI

struct ContextPickerItemView: View {
    private let currentWindowIconUrl: URL?
    private let imageRes: ImageResource
    private let title: String
    private let subtitle: String
    
    init(
        currentWindowIconUrl: URL? = nil,
        imageRes: ImageResource,
        title: String,
        subtitle: String
    ) {
        self.currentWindowIconUrl = currentWindowIconUrl
        self.imageRes = imageRes
        self.title = title
        self.subtitle = subtitle
    }
    
    private var windowIcon: NSImage? {
        guard let url = currentWindowIconUrl else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    var body: some View {
        HStack(spacing: 0) {
            if let windowIcon = windowIcon {
                Image(nsImage: windowIcon)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .cornerRadius(4.5)
                    .padding(.leading, 12)
            } else {
                Image(imageRes)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding(.leading, 12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appFont(.medium14)
                    .foregroundColor(.white)
                Text(subtitle)
                    .appFont(.medium13)
                    .foregroundColor(.gray200)
            }
            .padding(.leading, 8)
            .padding(.vertical, 6)
        }
        .frame(minWidth: 210, alignment: .leading)
    }
}

#Preview {
    ContextPickerItemView(currentWindowIconUrl: nil, imageRes: .arrowsSpin, title: "", subtitle: "")
}
