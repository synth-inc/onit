//
//  ContextItem.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct ContextItem: View {
    @Environment(\.model) var model

    var item: Context
    var isSent: Bool

    var imageRect: RoundedRectangle {
        .rect(cornerRadius: 3)
    }

    var body: some View {
        HStack(spacing: 0) {
            image

            Spacer()
                .frame(width: 4)

            text
            if !isSent {
                xButton
            }
        }
        .padding(3)
        .background(.gray700, in: .rect(cornerRadius: 4))
    }

    @ViewBuilder
    var image: some View {
        switch item {
        case .image:
            imageImage
        case .file:
            fileImage
        default:
            warningImage
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
                Image(nsImage: NSImage(byReferencing: item.url))
                    .resizable()
                    .scaledToFill()
            }
            .imageProgress(url: item.url)
            .clipShape(imageRect)
            .overlay {
                imageRect
                    .strokeBorder(.gray500)
            }
    }

    var warningImage: some View {
        Image(.warning)
            .resizable()
            .frame(width: 16, height: 16)
    }

    var text: some View {
        HStack(spacing: 2) {
            Text(name)
                .foregroundStyle(.white)
            if let fileType = item.fileType {
                Text(fileType)
                    .foregroundStyle(.gray200)
            }
        }
        .appFont(.medium13)
    }

    var name: String {
        switch item {
        case .file(let url), .image(let url):
            url.lastPathComponent
        case .error(_, let error):
            error.localizedDescription
        case .tooBig:
            "Upload exceeds model limit"
        }
    }

    var xButton: some View {
        Button {
            model.removeContext(context: item)
        } label: {
            Color.clear
                .frame(width: 16, height: 16)
                .overlay {
                    Image(.smallCross)
                }
        }
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        ContextItem(item: .file(URL(fileURLWithPath: "")), isSent: false)
    }
}
#endif
