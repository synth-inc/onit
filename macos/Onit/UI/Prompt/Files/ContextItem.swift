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
                    action: showContextWindow,
                    removeAction: removeContextItem
                )
            case .auto(let autoContext):
                tagButton(
                    text: name,
                    iconBundleURL: autoContext.appBundleUrl,
                    tooltip: isEditing ? (hasError ? errorMessage : name) : "View auto-context file",
                    errorDotColor: hasError ? .red : nil,
                    action: showContextWindow,
                    removeAction: isEditing ? { removeContextItem() } : nil   
                )
            case .text(let text):
                tagButton(
                    text: "Text: \(name)",
                    iconView: ContextImage(context: item),
                    tooltip: "Highlighted text",
                    action: { state.selectedHighlightedText = text },
                    removeAction: isEditing ? {
                        removeContextItem()
                        
                        if state.selectedHighlightedText == text {
                            state.selectedHighlightedText = nil
                        }
                    } : nil
                )
            default:
                tagButton(
                    text: name,
                    iconView: ContextImage(context: item),
                    tooltip: isEditing ? name : "View \(item.fileType ?? "") file",
                    action: showContextWindow,
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
        case .text(let text):
            text.selectedText
        }
    }
    
    
     private var hasError: Bool {
         if case .auto(let autoContext) = item {
             return autoContext.appContent["error"] != nil
         }
         return false
     }
     
     private var errorMessage: String {
         if case .auto(let autoContext) = item,
            let error = autoContext.appContent["error"] as? String {
             return error
         }
         return name
     }
}

// MARK: - Child Components

extension ContextItem {
    private func tagButton(
        text: String,
        iconBundleURL: URL? = nil,
        iconView: (any View)? = nil,
        tooltip: String,
        action: @escaping () -> Void,
        removeAction: (() -> Void)? = nil
    ) -> some View {
        ContextTag(
            text: text,
            textColor: isEditing ? .T_2 : Color.primary,  
            background: isEditing ? .gray500 : .clear,
            hoverBackground: isEditing ? .gray400 : .gray600,
            iconBundleURL: iconBundleURL,
            iconView: iconView,
            tooltip: tooltip,
            action: action,
            removeAction: removeAction
        )
    }
}

// MARK: - Private Functions

extension ContextItem {
    private func getTextContextBorderColor(_ text: String) -> Color {
        if let selectedHighlightedText = state.selectedHighlightedText,
           selectedHighlightedText.selectedText == text
        {
            if isEditing {
                return .gray400
            } else {
                return .gray600
            }
        } else {
            return .clear
        }
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
