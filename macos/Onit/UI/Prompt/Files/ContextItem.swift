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
            case .web(let url, _):
                WebContextItem(item: item, url: url, title: url.host() ?? url.absoluteString, isEditing: isEditing)
            case .auto:
                Button {
                    model.showAutoContextWindow(context: item)
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
        case .web(let url, _):
            url.host() ?? url.absoluteString
        }
    }

    var xButton: some View {
        Button {
            model.closeAutoContextWindow(context: item)
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
