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
                    textColor: isEditing ? autoContextTextColor : .white,
                    hoverTextColor: isEditing ? autoContextHoverTextColor : .white,
                    background: isEditing ? autoContextBackground : .clear,
                    hoverBackground: isEditing ? autoContextHoverBackground : .gray600,
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
                    textColor: isEditing ? .T_2 : .white,
                    background: isEditing ? .gray500 : .clear,
                    hoverBackground: isEditing ? .gray400 : .gray600,
                    maxWidth: isEditing ? 155 : .infinity,
                    iconView: ContextImage(context: item),
                    caption: item.fileType,
                    tooltipPrompt: isEditing ? name : "View \(item.fileType ?? "") file",
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
        return .T_2
    }
    
    private var autoContextHoverTextColor: Color {
        return .white
    }
    
    private var autoContextBackground: Color {
        if hasError {
            return .redDisabled
        } else if hasWarning {
            return .warningDisabled
        } else {
            return .gray500
        }
    }
    
    private var autoContextHoverBackground: Color {
        if hasError {
            return .redDisabledHover
        } else if hasWarning {
            return .warningDisabledHover
        } else {
            return .gray400
        }
    }
    
    private var autoContextErrorDotColor: Color? {
        if hasError {
            return .red
        } else if hasWarning {
            return .yellow
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
