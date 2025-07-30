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
                ContextTag(
                    text: name,
                    textColor: isEditing ? autoContextTextColor : Color.S_0,
                    hoverTextColor: isEditing ? autoContextHoverTextColor : Color.S_0,
                    background: isEditing ? autoContextBackground : Color.clear,
                    hoverBackground: isEditing ? autoContextHoverBackground : Color.T_9,
                    maxWidth: isEditing ? 155 : .infinity,
                    iconBundleURL: autoContext.appBundleUrl,
                    tooltip: isEditing ? name : "View auto-context file",
                    errorDotColor: autoContextErrorDotColor,
                    action: showContextWindow,
                    removeAction: isEditing ? { removeContextItem() } : nil   
                )
            default:
                ContextTag(
                    text: name,
                    textColor: isEditing ? Color.T_2 : Color.S_0,
                    background: isEditing ? Color.T_8 : Color.clear,
                    hoverBackground: isEditing ? Color.S_4 : Color.T_9,
                    maxWidth: isEditing ? 155 : .infinity,
                    iconView: ContextImage(context: item),
                    caption: item.fileType,
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
            var name = autoContext.appTitle
            if hasError {
                name = errorMessage
            } else if hasWarning {
                name = warningMessage
            }
            if let matchPercentage = autoContext.ocrMatchingPercentage {
                name = "\(matchPercentage)% \(name)"
            }
            return name
        case .file(let url), .image(let url):
            return url.lastPathComponent
        case .error(_, let error):
            return error.localizedDescription
        case .tooBig:
            return "Upload exceeds model limit"
        case .webSearch(let title, _, _, _):
            return title
        case .web(let websiteUrl, let websiteTitle, _):
            return websiteTitle.isEmpty ? websiteUrl.host() ?? websiteUrl.absoluteString : websiteTitle
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
            let error = autoContext.appContent["error"] {
            return error
        }
        return name
    }

    private var hasWarning: Bool {
        if case .auto(let autoContext) = item {
            return autoContext.appContent["warning"] != nil
        }
        return false
    }

    private var warningMessage: String {
        if case .auto(let autoContext) = item,
           let warning = autoContext.appContent["warning"] {
            return warning
        }
        return name
    }
        
    private var autoContextTextColor: Color {
        return Color.T_2
    }
    
    private var autoContextHoverTextColor: Color {
        return Color.S_0
    }
    
    private var autoContextBackground: Color {
        if hasError {
            return Color.redDisabled
        } else if hasWarning {
            return Color.warningDisabled
        } else {
            return Color.T_8
        }
    }
    
    private var autoContextHoverBackground: Color {
        if hasError {
            return Color.redDisabledHover
        } else if hasWarning {
            return Color.warningDisabledHover
        } else {
            return Color.S_4
        }
    }
    
    private var autoContextErrorDotColor: Color? {
        if hasError {
            return Color.red500
        } else if hasWarning {
            return Color.orange500
        } else {
            return nil
        }
    }
}

// MARK: - Private Functions

extension ContextItem {
    private func showContextWindow() {
        guard let state = state else { return }
        ContextWindowsManager.shared.showContextWindow(
            windowState: state,
            context: item
        )
    }
    
    private func removeContextItem() {
        ContextWindowsManager.shared.deleteContextItem(
            item: item
        )
        state?.removeContext(context: item)
    }
}

// MARK: - Preview

#if DEBUG
    #Preview {
        ContextItem(item: .file(URL(fileURLWithPath: "")))
    }
#endif
