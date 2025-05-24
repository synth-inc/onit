//
//  ContextPickerItemView.swift
//  Onit
//
//  Created by Kévin Naudin on 28/01/2025.
//

import SwiftUI

struct ContextPickerItemView: View {
    private let imageRes: ImageResource
    private let title: String
    private let subtitle: String
    private let currentWindowBundleUrl: URL?
    
    init(
        imageRes: ImageResource,
        title: String,
        subtitle: String,
        currentWindowBundleUrl: URL? = nil
    ) {
        self.imageRes = imageRes
        self.title = title
        self.subtitle = subtitle
        self.currentWindowBundleUrl = currentWindowBundleUrl
    }
    
    private var windowIcon: NSImage? {
        guard let bundleUrl = currentWindowBundleUrl else { return nil }
        return NSWorkspace.shared.icon(forFile: bundleUrl.path)
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
    ContextPickerItemView(imageRes: .arrowsSpin, title: "", subtitle: "", currentWindowBundleUrl: nil)
}
