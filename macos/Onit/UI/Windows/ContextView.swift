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
    @State private var text: String? 
    @State private var showOCRDetails = false
    @State private var ocrComparisonResult: OCRComparisonResult? = nil
    @ObservedObject private var debugManager = DebugManager.shared

    var context: Context
    var webFileContents: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if !closedAutoContextDialog {
                    dialog
                }
                
                if shouldShowOCRWarning {
                    ocrWarningDialog
                }

                if let text = text {
                    Text(text)
                        .appFont(.medium14)
                        .padding(.top, (!closedAutoContextDialog || shouldShowOCRWarning) ? 0 : 16)
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
                updateOCRComparisonResult()
            }
            .onChange(of: debugManager.ocrComparisonResults) { _, _ in
                updateOCRComparisonResult()
            }
        }
        .frame(idealWidth: 569, minHeight: 370, maxHeight: 569)
        .fixedSize(horizontal: true, vertical: false)
        .sheet(isPresented: $showOCRDetails) {
            if let ocrResult = ocrComparisonResult {
                OCRDetailSheet(result: ocrResult)
            }
        }
    }
    
    private var shouldShowOCRWarning: Bool {
        guard case .auto(let autoContext) = context,
              let matchPercentage = autoContext.ocrMatchingPercentage else {
            return false
        }
        return matchPercentage < 75
    }
    
    private var ocrWarningDialog: some View {
        guard case .auto(let autoContext) = context,
              let matchPercentage = autoContext.ocrMatchingPercentage else {
            return AnyView(EmptyView())
        }
        
        let title = "Only \(matchPercentage)% was successfully fetched"
        let buttonBackgroundColor = matchPercentage < 50 ? Color.redDisabled : Color.warningDisabled
        let buttonTextColor = matchPercentage < 50 ? Color.red : Color.yellow
        
        return AnyView(
            SetUpDialog(title: title, showButton: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("A significant amount of content may be missing from your context. This can affect accuracy.")
                    
                    HStack {
                        Spacer()
                        Button("View Report") {
                            showOCRDetails = true
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(buttonBackgroundColor)
                        .foregroundColor(buttonTextColor)
                        .cornerRadius(6)
                    }
                }
            } action: {
                
            } closeAction: {
                // For now, we don't allow closing the OCR warning
                // Users should be aware of the data quality issue
            }
            .fixedSize(horizontal: false, vertical: true)
        )
    }
    
    private func updateOCRComparisonResult() {
        guard case .auto(let autoContext) = context else {
            ocrComparisonResult = nil
            return
        }
        
        // Find the most recent OCR result that matches this auto context
        ocrComparisonResult = debugManager.ocrComparisonResults
            .filter { result in
                result.appTitle == autoContext.appTitle &&
                Date().timeIntervalSince(result.timestamp) < 300 // Within last 5 minutes
            }
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }
    
    private func getDialogInfo() -> (String, String) {
        switch context {
        case .auto(_):
            return ("AutoContext", "AutoContext is collected as plain text from your current window. You can manage your AutoContext preferences in settings.")
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
        case .auto(let autoContext):
            return autoContext.appTitle
        case .web(let websiteUrl, let websiteTitle, _):
            let websiteUrlDomain = websiteUrl.host() ?? websiteUrl.absoluteString
            return websiteTitle.isEmpty ? websiteUrlDomain : websiteTitle
        default:
            return ""
        }
    }

    private var readableContent: String {
        switch context {
        case .auto(let autoContext):
            return autoContext.appContent
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
    ContextView(context: .init(appName: "Test", appHash: 0, appTitle: "", appContent: [:]), webFileContents: "Test")
}
