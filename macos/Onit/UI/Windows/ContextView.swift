//
//  ContextView.swift
//  Onit
//
//  Created by Kévin Naudin on 27/01/2025.
//

import Defaults
import SwiftUI
import GoogleSignIn

struct ContextView: View {
    @Default(.closedAutoContextDialog) var closedAutoContextDialog
    @State private var text: String? = nil
    @State var windowState: OnitPanelState

    @State private var showOCRDetails = false
    @State private var ocrComparisonResult: OCRComparisonResult? = nil {
        didSet {
            if ocrComparisonResult == nil {
                print("ocrComparisonResult set to nil")
            } else {
                print("ocrComparisonResult set to non-nil")
            }
        }
    }
    
    @ObservedObject private var debugManager = DebugManager.shared

    let initialContext: Context
    var webFileContents: String

    // Computed property to get the current context from state
    private var context: Context {
        guard case .auto(let autoContext) = initialContext else { return initialContext }

        // Find the current context in the window state that matches our appHash
        if let currentContext = windowState.pendingContextList.first(where: { ctx in
            if case .auto(let currentAutoContext) = ctx {
                return currentAutoContext.appHash == autoContext.appHash &&
                       currentAutoContext.appTitle == autoContext.appTitle
            }
            return false
        }) {
            return currentContext
        }

        // Fallback to initial context if not found in state
        return initialContext
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if hasError {
                    errorDialog
                } else if !closedAutoContextDialog {
                    dialog
                }

                if !hasError {
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
            }
            .task(id: context.hashValue) {
                text = readableContent
            }
            .onAppear() {
                updateOCRComparisonResult()
            }
        }
        .frame(idealWidth: 569, minHeight: 370, maxHeight: 569)
        .fixedSize(horizontal: true, vertical: false)
        .sheet(isPresented: $showOCRDetails) {
            // There is a weird SwiftUI bug here. We need to get the OCR result in this closure.
            // It fails when we try to use the "ocrComparisonResult" variable.
            // My guess is that it has to do with being a struct. - TIM
            if let ocrResult = getOCRComparisonResult() {
                OCRDetailSheet(result: ocrResult)
            }
        }
    }
    
    private func updateOCRComparisonResult() {
        ocrComparisonResult = getOCRComparisonResult()
    }
    
    private func getOCRComparisonResult() -> OCRComparisonResult? {
        guard case .auto(let autoContext) = context else {
            ocrComparisonResult = nil
            return nil
        }
        
        // Find the most recent OCR result that matches this auto context
        return debugManager.ocrComparisonResults
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
    
    private var hasError: Bool {
        if case .auto(let autoContext) = context {
            return autoContext.appContent["error"] != nil
        }
        return false
    }
    
    private var errorTitle: String {
        if case .auto(let autoContext) = context,
           let error = autoContext.appContent["error"] as? String {
            return error
        }
        return "Error"
    }
    
    private var errorCode: String? {
        if case .auto(let autoContext) = context {
            return autoContext.appContent["errorCode"] as? String
        }
        return nil
    }
    
    private func getErrorDialogInfo() -> (String, String) {
        switch errorCode {
        case "1500":
            return ("To fetch your Google Drive tabs as window context, you'll need to connect your account. Please authenticate with Google Drive and try again.", "Connect Google Drive")
        case "1501":
            return ("Give permission to Onit to view this drive file.", "Grant Permission")
        case "1800":
            return ("A significant amount of content may be missing from your context. This can affect accuracy.", "View Report")
        default:
            return ("An error occurred while fetching context.", "OK")
        }
    }
    
    private func retryContextExtraction() {
        guard case .auto(let autoContext) = context else { return }

        let state = PanelStateCoordinator.shared.getState(for: autoContext.appHash)

        state?.removeContext(context: context)

        let trackedWindow = AccessibilityNotificationsManager.shared.windowsManager.findTrackedWindow(trackedWindowHash: autoContext.appHash)

        AccessibilityNotificationsManager.shared.retrieveWindowContent(
            state: state,
            trackedWindow: trackedWindow,
            customAppBundleUrl: autoContext.appBundleUrl
        )
    }

    var errorDialog: some View {
        let (subtitle, buttonText) = getErrorDialogInfo()
        return SetUpDialog(
            title: errorTitle,
            icon: "warning",
            titleColor: .red,
            buttonText: buttonText,
            buttonStyle: .default
        ) {
            Text(subtitle)
        } action: {
            if errorCode == "1500" {
                GoogleDriveService.shared.authorizeGoogleDrive {
                    Task { @MainActor in
                        self.retryContextExtraction()
                    }
                }
            } else if errorCode == "1501" {
                Task {
                    await GoogleDriveService.shared.showGoogleDrivePicker {
                        Task { @MainActor in
                            self.retryContextExtraction()
                        }
                    }
                }
            } else if errorCode == "1800" {
                updateOCRComparisonResult()
                if ocrComparisonResult != nil {
                    ocrToShow = ocrComparisonResult
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showOCRDetails = true
//                    }
                }
                
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ContextView(
        windowState: OnitPanelState(),
        initialContext: .init(appName: "Test", appHash: 0, appTitle: "", appContent: [:]),
        webFileContents: "Test"
    )
}
