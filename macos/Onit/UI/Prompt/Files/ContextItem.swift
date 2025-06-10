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

    var body: some View {
        HStack(spacing: 0) {
            switch item {
            case .web(_, _, _):
                WebContextItem(
                    item: item,
                    isEditing: isEditing,
                    action: showContextMenu,
                    removeAction: removeContextItem
                )
            case .auto(let autoContext):
                ContextTag(
                    text: name,
                    textColor: isEditing ? .T_2 : .white,
                    background: isEditing ? .gray500 : .clear,
                    hoverBackground: isEditing ? .gray400 : .gray600,
                    maxWidth: isEditing ? 155 : .infinity,
                    iconBundleURL: autoContext.appBundleUrl,
                    tooltip: isEditing ? name : "View auto-context file",
                    action: showContextMenu,
                    removeAction: isEditing ? { removeContextItem() } : nil
                )
            default:
                ContextTag(
                    text: name,
                    textColor: isEditing ? .T_2 : .white,
                    background: isEditing ? .gray500 : .clear,
                    hoverBackground: isEditing ? .gray400 : .gray600,
                    maxWidth: isEditing ? 155 : .infinity,
                    iconView: ContextImage(context: item),
                    caption: item.fileType,
                    tooltip: isEditing ? name : "View \(item.fileType ?? "") file",
                    action: showContextMenu,
                    removeAction: isEditing ? { removeContextItem() } : nil
                )
            }
        }
    }

    var name: String {
        switch item {
        case .auto(let autoContext):
            autoContext.appTitle
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
    private func showContextMenu() {
        state.showContextMenu = true
    }
    
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
