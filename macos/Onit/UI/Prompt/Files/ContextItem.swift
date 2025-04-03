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
    var isEditing: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            switch item {
            case .web(_, _, _):
                WebContextItem(
                    item: item,
                    isEditing: isEditing
                )
            case .auto:
                Button {
                    model.showContextWindow(context: item)
                } label: {
                    contentView
                }
                .tooltip(prompt: "View auto-context file")
            default:
                contentView
            }

            if isEditing {
                xButton
            }
        }
        .padding(3)
        .background(isEditing ? .gray700 : .clear, in: .rect(cornerRadius: 4))
        .frame(maxWidth: item.isError ? 350 : isEditing ? 250 : nil)
    }

    var contentView: some View {
        HStack(spacing: 0) {
            ContextImage(context: item)

            Spacer()
                .frame(width: 4)

            text
        }
    }

    var text: some View {
        HStack(spacing: 2) {
            Text(name)
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
            if let fileType = item.fileType {
                Text(fileType)
                    .foregroundStyle(.gray200)
            }
        }
        .appFont(.medium13)
    }

    var name: String {
        switch item {
        case .auto(let appName, _):
            appName
        case .file(let url), .image(let url):
            url.lastPathComponent
        case .error(_, let error):
            error.localizedDescription
        case .tooBig:
            "Upload exceeds model limit"
        case .webSearch(let title, _, _, _):
            title
        case .web(let websiteUrl, let websiteTitle, _):
            websiteTitle.isEmpty ? websiteUrl.host() ?? websiteUrl.absoluteString : websiteTitle
        }
    }

    var xButton: some View {
        Button {
            model.closeContextWindow(context: item)
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
            ContextItem(item: .file(URL(fileURLWithPath: "")))
        }
    }
#endif
