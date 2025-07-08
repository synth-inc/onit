//
//  GoogleDriveService.swift
//  Onit
//
//  Created by Jay Swanson on 6/17/25.
//

import Foundation
@preconcurrency import GoogleSignIn
import SwiftUI
import WebKit

@MainActor
class GoogleDriveService: NSObject, ObservableObject {
    static let shared = GoogleDriveService()

    // Auth states
    @Published var isAuthorized = false
    @Published var userEmail: String?
    @Published var isAuthorizing = false
    @Published var isDisconnecting = false
    @Published var authorizationError: String?

    // Extraction states
    @Published var extractedText: String?
    @Published var isExtracting = false
    @Published var extractionError: String?

    // Picker states
    @Published var isShowingPicker = false
    @Published var pickerError: String?

    // Internal picker state
    private var pickerAPIKey: String?
    private var pendingExtractionUrl: String?
    private var pickerWindow: NSWindow?
    private var pickerWebView: WKWebView?
    private var successCallback: (() -> Void)?

    func checkAuthorizationStatus() -> Bool {
        guard let googleUser = GIDSignIn.sharedInstance.currentUser else {
            self.isAuthorized = false
            self.userEmail = nil
            return false
        }

        if let grantedScopes = googleUser.grantedScopes,
            grantedScopes.contains("https://www.googleapis.com/auth/drive.file")
        {
            self.isAuthorized = true
            self.userEmail = googleUser.profile?.email
            return true
        } else {
            self.isAuthorized = false
            self.userEmail = nil
            return false
        }
    }

    func authorizeGoogleDrive(onSuccess: (() -> Void)? = nil) {
        self.isAuthorizing = true
        self.authorizationError = nil

        guard let window = NSApp.keyWindow else {
            print("Couldn't get key window")
            self.isAuthorizing = false
            return
        }

        let completion: (GIDSignInResult?, Error?) -> Void = { result, error in
            self.handleAuthorizationResult(result: result, error: error, onSuccess: onSuccess)
        }

        if let googleUser = GIDSignIn.sharedInstance.currentUser {
            googleUser.addScopes(
                ["https://www.googleapis.com/auth/drive.file"],
                presenting: window,
                completion: completion
            )
        } else {
            GIDSignIn.sharedInstance.signIn(
                withPresenting: window,
                hint: nil,
                additionalScopes: ["https://www.googleapis.com/auth/drive.file"],
                completion: completion
            )
        }
    }

    private func handleAuthorizationResult(result: GIDSignInResult?, error: Error?, onSuccess: (() -> Void)? = nil) {
        guard let result = result else {
            if let error = error as? NSError, error.domain == "com.google.GIDSignIn",
                error.code == -5
            {
                // The user canceled the auth flow
                self.isAuthorizing = false
                return
            } else if let error = error {
                self.authorizationError = error.localizedDescription
                self.isAuthorizing = false
            } else {
                self.authorizationError = "Unknown Google auth error"
                self.isAuthorizing = false
            }
            return
        }

        self.isAuthorized = true
        self.userEmail = result.user.profile?.email
        self.authorizationError = nil
        self.isAuthorizing = false

        onSuccess?()
    }

    func disconnectGoogleDrive() {
        self.isDisconnecting = true
        self.authorizationError = nil

        GIDSignIn.sharedInstance.disconnect { error in
            Task { @MainActor in
                if let error = error {
                    let errorMsg = error.localizedDescription

                    self.authorizationError = errorMsg
                    self.isDisconnecting = false
                    return
                }

                self.isAuthorized = false
                self.userEmail = nil
                self.authorizationError = nil
                self.isDisconnecting = false
            }
        }
    }

    func extractTextFromGoogleDrive(driveUrl: String) async throws -> String {
        self.isExtracting = true
        self.extractionError = nil

        guard !driveUrl.isEmpty else {
            let error = "Please enter a Google Drive URL"
            self.extractionError = error
            self.isExtracting = false
            throw GoogleDriveServiceError.invalidUrl(error)
        }

        // Extract file ID from Google Drive URL
        guard let fileId = extractFileIdFromUrl(driveUrl) else {
            let error = "Invalid Google Drive URL format"
            self.extractionError = error
            self.isExtracting = false
            throw GoogleDriveServiceError.invalidUrl(error)
        }

        _ = try? await GIDSignIn.sharedInstance.currentUser?.refreshTokensIfNeeded()

        guard let user = GIDSignIn.sharedInstance.currentUser else {
            let error = "Not authenticated with Google Drive"
            self.extractionError = error
            self.isExtracting = false
            throw GoogleDriveServiceError.notAuthenticated(error)
        }

        // Get the access token (tokens are automatically refreshed by Google Sign-In SDK)
        let accessToken = user.accessToken.tokenString

        // Determine document type and appropriate MIME type for export
        let mimeType = getMimeTypeForUrl(driveUrl)

        // Use Google Drive API to export the document
        let exportUrl =
            "https://www.googleapis.com/drive/v3/files/\(fileId)/export?mimeType=\(mimeType)"

        guard let url = URL(string: exportUrl) else {
            let error = "Invalid export URL"
            self.extractionError = error
            self.isExtracting = false
            throw GoogleDriveServiceError.invalidUrl(error)
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        self.isExtracting = false

        guard let httpResponse = response as? HTTPURLResponse else {
            let error = "Invalid response"
            self.extractionError = error
            throw GoogleDriveServiceError.invalidResponse(error)
        }

        if httpResponse.statusCode == 404 {
            let extractionError =
                "Onit needs permission to access this file."
            self.extractionError = extractionError
            throw GoogleDriveServiceError.notFound(extractionError)
        } else if httpResponse.statusCode == 403 {
            var extractionError =
                "Onit can't access this file."
            if let errorMessage = extractApiErrorMessage(from: data) {
                extractionError += "\n\nError message: \(errorMessage)"
            }
            self.extractionError = extractionError
            throw GoogleDriveServiceError.accessDenied(extractionError)
        } else if httpResponse.statusCode != 200 {
            var extractionError =
                "Failed to retrieve document (HTTP \(httpResponse.statusCode))"
            if let errorMessage = extractApiErrorMessage(from: data) {
                extractionError += "\n\nError message: \(errorMessage)"
            }
            self.extractionError = extractionError
            throw GoogleDriveServiceError.httpError(httpResponse.statusCode, extractionError)
        }

        guard let text = String(data: data, encoding: .utf8) else {
            let error = "Failed to decode document content"
            self.extractionError = error
            throw GoogleDriveServiceError.decodingError(error)
        }

        if text.isEmpty {
            return "(Document appears to be empty)"
        } else {
            return text
        }
    }

    private func extractApiErrorMessage(from data: Data) -> String? {
        if let googleDriveError = try? JSONDecoder().decode(GoogleDriveAPIError.self, from: data),
           let errorMessage = googleDriveError.error?.message {
            return errorMessage
        }
        return String(data: data, encoding: .utf8)
    }

    private func getMimeTypeForUrl(_ url: String) -> String {
        if url.contains("docs.google.com/document") {
            return "text/plain"
        } else if url.contains("docs.google.com/spreadsheets") {
            return "text/csv"
        } else if url.contains("docs.google.com/presentation") {
            return "text/plain"
        } else {
            // Default to text/plain for generic drive URLs
            return "text/plain"
        }
    }

    private func extractFileIdFromUrl(_ url: String) -> String? {
        // Handle various Google Drive URL formats
        let patterns = [
            #"https://docs\.google\.com/document/d/([a-zA-Z0-9-_]+)"#,
            #"https://drive\.google\.com/file/d/([a-zA-Z0-9-_]+)"#,
            #"https://docs\.google\.com/spreadsheets/d/([a-zA-Z0-9-_]+)"#,
            #"https://docs\.google\.com/presentation/d/([a-zA-Z0-9-_]+)"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
                let match = regex.firstMatch(
                    in: url, range: NSRange(location: 0, length: url.count)),
                let fileIdRange = Range(match.range(at: 1), in: url)
            {
                return String(url[fileIdRange])
            }
        }

        return nil
    }

    // MARK: - Google Drive Picker

    public func showGoogleDrivePicker(onSuccess: (() -> Void)? = nil) async {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            self.extractionError = "Not authenticated with Google Drive"
            return
        }

        self.isShowingPicker = true
        self.pickerError = nil

        let accessToken = user.accessToken.tokenString
        let clientId = GIDSignIn.sharedInstance.configuration?.clientID ?? ""

        // Create picker window
        let windowRect = NSRect(x: 0, y: 0, width: 800, height: 600)
        pickerWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        pickerWindow?.title = "Select Google Drive File"
        pickerWindow?.center()
        pickerWindow?.isReleasedWhenClosed = false

        // Create WebView with picker
        let webViewConfig = WKWebViewConfiguration()

        // Add message handlers for JavaScript communication
        let contentController = WKUserContentController()
        contentController.add(self, name: "fileSelected")
        contentController.add(self, name: "pickerCancelled")
        webViewConfig.userContentController = contentController

        pickerWebView = WKWebView(frame: windowRect, configuration: webViewConfig)
        pickerWebView?.navigationDelegate = self

        if let webView = pickerWebView {
            pickerWindow?.contentView = webView

            if pickerAPIKey == nil {
                let client = FetchingClient()
                do {
                    pickerAPIKey = try await client.getGooglePickerAPIKey()
                } catch {
                    pickerError = "Failed to fetch Google Picker API key: \(error)"
                }
            }

            guard let apiKey = pickerAPIKey else {
                self.pickerError = "Failed to fetch Google Picker API key"
                return
            }

            // Load Google Drive Picker
            let pickerHTML = createPickerHTML(
                accessToken: accessToken, clientId: clientId, apiKey: apiKey)
            webView.loadHTMLString(pickerHTML, baseURL: URL(string: "https://www.google.com"))
        }

        // Show window
        if let window = pickerWindow {
            NSApp.keyWindow?.addChildWindow(window, ordered: .above)
            window.makeKeyAndOrderFront(nil)
        }

        self.successCallback = onSuccess
    }

    private func createPickerHTML(accessToken: String, clientId: String, apiKey: String) -> String {
        return """
            <!DOCTYPE html>
            <html>
                <head>
                    <title>Google Drive Picker</title>
                    <script src="https://apis.google.com/js/api.js"></script>
                    <script src="https://accounts.google.com/gsi/client"></script>
                </head>
                <body>
                    <script>
                        function onApiLoad() {
                            gapi.load("picker", createPicker);
                        }

                        function createPicker() {
                            const picker = new google.picker.PickerBuilder()
                                .addView(google.picker.ViewId.DOCS)
                                .setOAuthToken("\(accessToken)")
                                .setDeveloperKey("\(apiKey)")
                                .setAppId("\(clientId)")
                                .setCallback(pickerCallback)
                                .build();
                            picker.setVisible(true);
                        }

                        function pickerCallback(data) {
                            if (data[google.picker.Response.ACTION] == google.picker.Action.PICKED) {
                                const file = data[google.picker.Response.DOCUMENTS][0];
                                const fileId = file[google.picker.Document.ID];
                                const fileName = file[google.picker.Document.NAME];

                                // Notify Swift code about the selected file
                                window.webkit.messageHandlers.fileSelected.postMessage({
                                    fileId: fileId,
                                    fileName: fileName,
                                    url: "https://docs.google.com/document/d/" + fileId,
                                });
                            } else if (data[google.picker.Response.ACTION] == google.picker.Action.CANCEL) {
                                window.webkit.messageHandlers.pickerCancelled.postMessage({});
                            }
                        }

                        // Load the API
                        onApiLoad();
                    </script>
                </body>
            </html>
            """
    }

    private func handlePickerFileSelection(fileId: String, fileName: String, url: String) {
        // Retry extraction with the selected file
        if let pendingUrl = pendingExtractionUrl,
            extractFileIdFromUrl(pendingUrl) == extractFileIdFromUrl(url)
        {
            Task {
                try? await self.extractTextFromGoogleDrive(driveUrl: url)
            }
        }

        // Call the success callback if provided
        successCallback?()

        // Close picker
        closePicker()
    }

    private func closePicker() {
        self.isShowingPicker = false

        // Clean up message handlers
        if let webView = pickerWebView {
            webView.configuration.userContentController.removeScriptMessageHandler(
                forName: "fileSelected")
            webView.configuration.userContentController.removeScriptMessageHandler(
                forName: "pickerCancelled")
        }

        if let window = pickerWindow {
            window.orderOut(nil)
            NSApp.keyWindow?.removeChildWindow(window)
        }

        pickerWindow = nil
        pickerWebView = nil
        pendingExtractionUrl = nil
        successCallback = nil
    }
}

// MARK: - WKNavigationDelegate
extension GoogleDriveService: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // WebView finished loading
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.pickerError = "Failed to load Google Drive picker: \(error.localizedDescription)"
        closePicker()
    }
}

// MARK: - WKScriptMessageHandler
extension GoogleDriveService: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
    ) {
        switch message.name {
        case "fileSelected":
            if let body = message.body as? [String: Any],
                let fileId = body["fileId"] as? String,
                let fileName = body["fileName"] as? String,
                let url = body["url"] as? String
            {
                handlePickerFileSelection(fileId: fileId, fileName: fileName, url: url)
            }
        case "pickerCancelled":
            self.extractionError = "Google Drive file selection was cancelled"
            closePicker()
        default:
            break
        }
    }
}

enum GoogleDriveServiceError: Error, LocalizedError {
    case notAuthenticated(String)
    case decodingError(String)
    case notFound(String)
    case invalidUrl(String)
    case httpError(Int, String)
    case accessDenied(String)
    case invalidResponse(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated(let message):
            return "Not Authenticated: \(message)"
        case .decodingError(let message):
            return "Decoding Error: \(message)"
        case .notFound(let message):
            return "Not Found: \(message)"
        case .invalidUrl(let message):
            return "Invalid URL: \(message)"
        case .httpError(let code, let message):
            return "HTTP Error (\(code)): \(message)"
        case .accessDenied(let message):
            return "Access Denied: \(message)"
        case .invalidResponse(let message):
            return "Invalid Response: \(message)"
        }
    }
}

struct GoogleDriveAPIError: Codable {
    let error: ErrorObject?

    struct ErrorObject: Codable {
        let message: String?
    }
}
