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
                TagButton(
                    child: ContextImage(context: item),
                    text: name,
                    caption: item.fileType,
                    tooltip: "View auto-context file",
                    action: { model.showContextWindow(context: item) },
                    closeAction: { model.deleteContextItem(item: item) }
                )
            default:
                TagButton(
                    child: ContextImage(context: item),
                    text: name,
                    caption: item.fileType,
                    closeAction: { model.deleteContextItem(item: item) }
                )
            }
        }
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
}

// MARK: - Preview

#if DEBUG
    #Preview {
        ModelContainerPreview {
            ContextItem(item: .file(URL(fileURLWithPath: "")))
        }
    }
#endif
