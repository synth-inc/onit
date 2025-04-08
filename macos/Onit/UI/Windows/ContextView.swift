//
//  ContextView.swift
//  Onit
//
//  Created by Kévin Naudin on 27/01/2025.
//

import Defaults
import SwiftUI

struct ContextView: View {
    @Default(.closedAutoContextDialog) var closedAutoContextDialog
    @State private var text: String? = nil

    var context: Context
    var webFileContents: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if !closedAutoContextDialog {
                    dialog
                }

                if let text = text {
                    Text(text)
                        .appFont(.medium14)
                        .padding(.top, !closedAutoContextDialog ? 0 : 16)
                        .padding(.bottom, 16)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ProgressView("Loading context from \(readableTitle)...")
                        .controlSize(.small)
                }
            }
            .task {
                text = readableContent
            }
        }
        .frame(idealWidth: 569, minHeight: 370, maxHeight: 569)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private func getDialogInfo() -> (String, String) {
        switch context {
        case .auto(_, _):
            return ("Auto-context", "Auto-context is collected as plain text from your current window. You can manage your auto-context preferences in settings.")
        case .web(let websiteUrl, _, _):
            return ("Web Context", "Displaying content retrieved from \(websiteUrl.absoluteString).")
        default:
            return ("Context", "")
        }
    }
    
    var dialog: some View {
        let (title, text) = getDialogInfo()
        
        return SetUpDialog(title: title, showButton: false) {
            Text(text)
        } action: {

        } closeAction: {
            closedAutoContextDialog = true
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var readableTitle: String {
        switch context {
        case .auto(let appTitle, _):
            return appTitle
        case .web(let websiteUrl, let websiteTitle, _):
            let websiteUrlDomain = websiteUrl.host() ?? websiteUrl.absoluteString
            return websiteTitle.isEmpty ? websiteUrlDomain : websiteTitle
        default:
            return ""
        }
    }

    private var readableContent: String {
        switch context {
        case .auto(_, let appContent):
            return appContent
                .map(\.value)
                .joined(separator: "\n\n")
        case .web(_, _, _):
            return webFileContents
        default:
            return ""
        }
    }
}

#Preview {
    ContextView(context: .init(appName: "Test", appContent: [:]), webFileContents: "Test")
}
