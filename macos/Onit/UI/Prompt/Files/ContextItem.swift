//
//  ContextItem.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct ContextItem: View {
    @Environment(\.model) var model

    var item: URL

    var imageRect: RoundedRectangle {
        .rect(cornerRadius: 3)
    }

    var body: some View {
        HStack(spacing: 0) {
            image

            Spacer()
                .frame(width: 4)

            text
            xButton
        }
        .padding(3)
        .background(.gray700, in: .rect(cornerRadius: 4))
    }

    @ViewBuilder
    var image: some View {
        if isImageFile {
            imageImage
        } else {
            fileImage
        }
    }

    var fileImage: some View {
        Image(.file)
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
    }

    var imageImage: some View {
        Color.clear
            .frame(width: 16, height: 16)
            .overlay {
                Image(nsImage: NSImage(byReferencing: item))
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(imageRect)
            .overlay {
                imageRect
                    .strokeBorder(.gray500)
            }
    }

    var text: some View {
        HStack(spacing: 2) {
            Text(item.lastPathComponent)
                .foregroundStyle(.white)
            Text(fileType)
                .foregroundStyle(.gray200)
        }
        .appFont(.medium13)
    }

    var xButton: some View {
        Button {
            model.removeContext(url: item)
        } label: {
            Color.clear
                .frame(width: 16, height: 16)
                .overlay {
                    Image(.smallCross)
                }
        }
    }

    var isImageFile: Bool {
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "tiff", "bmp"]
        return imageExtensions.contains(item.pathExtension.lowercased())
    }

    var fileType: String {
        isImageFile ? "Img" : "file"
    }
}

#Preview {
    ContextItem(item: URL(fileURLWithPath: ""))
        .environment(OnitModel())
}
