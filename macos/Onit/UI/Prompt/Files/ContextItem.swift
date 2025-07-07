//
//  ContextItem.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import Defaults
import SwiftUI

struct ContextItem: View {
    @Environment(\.windowState) private var state
    
    @Default(.autoAddHighlightedTextToContext) var autoAddHighlightedTextToContext

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
                    tooltip: isEditing ? (hasError ? errorMessage : name) : "View auto-context file",
                    iconBundleURL: autoContext.appBundleUrl,
                    errorDotColor: hasError ? .red : nil,
                    action: showContextWindow,
                    removeAction: isEditing ? { removeContextItem() } : nil   
                )
            case .text(let text, let isPinned):
                tagButton(
                    text: "Text: \(name)",
                    tooltip: "Highlighted text",
                    isPinned: isPinned,
                    showIndicator: text.selectedText == state.currentHighlightedText,
                    indicatorOffset: 1,
                    iconView: ContextImage(context: item),
                    action: { state.selectedHighlightedText = text },
                    pinAction:
                        checkAllowTextPin(isPinned) ? {
                            togglePinned()
                        } : nil,
                    removeAction: isEditing ? {
                        removeContextItem()
                        
                        if state.selectedHighlightedText == text {
                            state.selectedHighlightedText = nil
                        }
                    } : nil
                )
                .onChange(of: autoAddHighlightedTextToContext) { _, new in
                    if !new && !isPinned {
                        togglePinned()
                    }
                }
                .onChange(of: state.currentHighlightedText) { _, highlightedText in
                    let highlightedTextUnselected = highlightedText == nil
                    
                    if highlightedTextUnselected && isEditing && !isPinned {
                        removeContextItem()
                    }
                }
            default:
                tagButton(
                    text: name,
                    tooltip: isEditing ? name : "View \(item.fileType ?? "") file",
                    iconView: ContextImage(context: item),
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
        case .text(let text, _):
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
        tooltip: String,
        isPinned: Bool = false,
        showIndicator: Bool = false,
        indicatorOffset: CGFloat = 0,
        iconBundleURL: URL? = nil,
        iconView: (any View)? = nil,
        errorDotColor: Color? = nil,
        action: @escaping () -> Void,
        pinAction: (() -> Void)? = nil,
        removeAction: (() -> Void)? = nil
    ) -> some View {
        ContextTag(
            text: text,
            textColor: isEditing ? .T_2 : Color.primary,  
            background: isEditing ? .gray500 : .clear,
            hoverBackground: isEditing ? .gray400 : .gray600,
            shouldFadeIn: autoAddHighlightedTextToContext && isPinned,
            showIndicator: showIndicator,
            indicatorOffset: indicatorOffset,
            iconBundleURL: iconBundleURL,
            iconView: iconView,
            tooltip: tooltip,
            errorDotColor: errorDotColor,
            action: action,
            pinAction: pinAction,
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
    
    private func checkAllowTextPin(_ isPinned: Bool) -> Bool {
        if isEditing && autoAddHighlightedTextToContext {
            let pendingContextList = state.getPendingContextList()
            
            let textContext = TextContextHelpers.getNotpinnedTextContext(
                contextList: pendingContextList
            )
            
            if isPinned { return textContext == nil }
            else { return true }
        } else {
            return false
        }
    }
    
    private func togglePinned() {
        switch item {
        case .text(let text, let isPinned):
            state.updateContext(
                oldContext: item,
                newContext: .text(text, !isPinned)
            )
        default:
            break
        }
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
