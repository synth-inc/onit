//
//  ContextItem.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct ContextItem: View {
    @Environment(\.windowState) private var state
    @ObservedObject private var debugManager = DebugManager.shared

    var item: Context
    var isEditing: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            switch item {
            case .web(_, _, _):
                WebContextItem(
                    item: item,
                    isEditing: isEditing,
                    showContextWindow: showContextWindow,
                    removeContextItem: removeContextItem
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
            if let matchPercentage = autoContext.ocrMatchingPercentage {
                "\(matchPercentage)% \(autoContext.appTitle)"
            } else {
                autoContext.appTitle
            }
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
    
    private var autoContextTextColor: Color {
        guard case .auto(let autoContext) = item,
              let matchPercentage = autoContext.ocrMatchingPercentage else {
            return .T_2
        }
        return .T_2
    }
    
    private var autoContextHoverTextColor: Color {
        guard case .auto(let autoContext) = item,
              let matchPercentage = autoContext.ocrMatchingPercentage else {
            return .white
        }
        return .white
    }
    
    private var autoContextBackground: Color {
        guard case .auto(let autoContext) = item,
              let matchPercentage = autoContext.ocrMatchingPercentage else {
            return .gray500
        }
        
        if matchPercentage < 50 {
            return .redDisabled
        } else if matchPercentage < 75 {
            return .warningDisabled
        } else {
            return .gray500
        }
    }
    
    private var autoContextHoverBackground: Color {
        guard case .auto(let autoContext) = item,
              let matchPercentage = autoContext.ocrMatchingPercentage else {
            return .gray400
        }
        
        if matchPercentage < 50 {
            return .redDisabledHover
        } else if matchPercentage < 75 {
            return .warningDisabledHover
        } else {
            return .gray400
        }
    }
    
    private var autoContextErrorDotColor: Color? {
        guard case .auto(let autoContext) = item,
              let matchPercentage = autoContext.ocrMatchingPercentage else {
            return nil
        }
        
        if matchPercentage < 50 {
            return .red
        } else if matchPercentage < 75 {
            return .yellow
        } else {
            return nil
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
