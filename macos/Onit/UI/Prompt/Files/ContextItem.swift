//
//  ContextItem.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct ContextItem: View {
    @Environment(\.windowState) private var state

    var item: Context
    var isEditing: Bool = true
    var inList: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            switch item {
            case .web(_, _, _):
                WebContextItem(
                    item: item,
                    isEditing: isEditing,
                    inList: inList,
                    showContextWindow: showContextWindow,
                    removeContextItem: removeContextItem
                )
            case .auto(let autoContext):
                if isEditing {
                    AutoContextButton(
                        icon: autoContext.appIcon,
                        text: name,
                        action: showContextWindow,
                        removeAction: inList ? nil : { removeContextItem() }
                    )
                } else {
                    TagButton(
                        child: ContextImage(context: item),
                        text: name,
                        caption: item.fileType,
                        tooltip: "View auto-context file",
                        action: showContextWindow,
                        closeAction: inList ? nil : { removeContextItem() },
                        fill: inList,
                        isTransparent: inList
                    )
                }
            default:
                TagButton(
                    child: ContextImage(context: item),
                    text: name,
                    caption: item.fileType,
                    closeAction: inList ? nil : { removeContextItem() },
                    fill: inList,
                    isTransparent: inList
                )
            }
        }
    }

    var name: String {
        switch item {
        case .auto(let autoContext):
            autoContext.appName
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

// MARK: - Private Functions

extension ContextItem {
    private func showContextWindow() {
        ContextWindowsManager.shared.showContextWindow(
            windowState: state,
            context: item
        )
    }
    
    private func removeContextItem() {
        ContextWindowsManager.shared.deleteContextItem(
            item: item
        )
        state.removeContext(context: item)
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        ContextItem(item: .file(URL(fileURLWithPath: "")))
    }
#endif
