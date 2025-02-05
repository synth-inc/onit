//
//  AutoContextView.swift
//  Onit
//
//  Created by Kévin Naudin on 27/01/2025.
//

import SwiftUI
import Defaults

struct AutoContextView: View {
    @Default(.closedAutoContextDialog) var closedAutoContextDialog
    @State private var text: String? = nil
    
    var context: Context
    
    var body: some View {
        ScrollView {
            VStack {
                if !closedAutoContextDialog {
                    dialog
                }
                
                if let text = text {
                    Text(text)
                        .appFont(.medium14)
                        .padding(.top, !closedAutoContextDialog ? 0: 16)
                        .padding(.bottom, 16)
                        .padding(.horizontal, 16)
                } else {
                    ProgressView("Loading auto context from \(readableTitle)...")
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
    
    var dialog: some View {
        SetUpDialog(title: "Auto-context", showButton: false) {
            Text("Auto-context is collected as plain text from your current window. You can manage your autocontext preferences in settings.")
        } action: {
            
        } closeAction: {
            closedAutoContextDialog = true
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private var readableTitle: String {
        guard case let .auto(appTitle, _) = context else {
            return ""
        }
        
        return appTitle
    }
    
    private var readableContent: String {
        guard case let .auto(_, appContent) = context else {
            return ""
        }
        
        return appContent
            .map(\.value)
            .joined(separator: "\n\n")
    }
}

#Preview {
    AutoContextView(context: .init(appName: "Test", appContent: [:]))
}
