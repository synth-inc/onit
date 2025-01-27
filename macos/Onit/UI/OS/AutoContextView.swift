//
//  AutoContextView.swift
//  Onit
//
//  Created by Kévin Naudin on 27/01/2025.
//

import SwiftUI

struct AutoContextView: View {
    @AppStorage("closedAutoContext") var closedDialog = false
    
    var context: Context
    
    var body: some View {
        ScrollView {
            VStack {
                if !closedDialog {
                    dialog
                }
                
                Text(readableContent)
                    .appFont(.medium14)
                    .padding(.top, !closedDialog ? 0: 16)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 16)
            }
        }
        .frame(idealWidth: 569, minHeight: 370, maxHeight: 569)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    var dialog: some View {
        SetUpDialog(title: "Auto-context", showButton: false) {
            Text("Auto-context is collected as plain text from your current window and only stored once you submit your prompt. You can manage your preferences and data in settings.")
        } action: {
            
        } closeAction: {
            closedDialog = true
        }
        .fixedSize(horizontal: false, vertical: true)
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
