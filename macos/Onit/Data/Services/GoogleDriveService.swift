//
//  GoogleDriveService.swift
//  Onit
//
//  Created by Jay Swanson on 6/17/25.
//

import Foundation
import GoogleSignIn
import SwiftUI
import WebKit

@MainActor
class GoogleDriveService: NSObject, ObservableObject {
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

    func checkAuthorizationStatus() {
        guard let googleUser = GIDSignIn.sharedInstance.currentUser else {
            self.isAuthorized = false
            self.userEmail = nil
            return
        }

        if let grantedScopes = googleUser.grantedScopes,
            grantedScopes.contains("https://www.googleapis.com/auth/drive.file")
        {
            self.isAuthorized = true
            self.userEmail = googleUser.profile?.email
        } else {
            self.isAuthorized = false
            self.userEmail = nil
        }
    }

    func authorizeGoogleDrive() {
        self.isAuthorizing = true
        self.authorizationError = nil

        guard let window = NSApp.keyWindow else {
            print("Couldn't get key window")
            self.isAuthorizing = false
            return
        }

        let completion: (GIDSignInResult?, Error?) -> Void = { result, error in
            self.handleAuthorizationResult(result: result, error: error)
        }

        if let googleUser = GIDSignIn.sharedInstance.currentUser {
            googleUser.addScopes(
                [
                    "https://www.googleapis.com/auth/drive.file"
                ],
                presenting: window,
                completion: completion
            )
        } else {
            GIDSignIn.sharedInstance.signIn(
                withPresenting: window,
                hint: nil,
                additionalScopes: [
                    "https://www.googleapis.com/auth/drive.file"
                ],
                completion: completion
            )
        }
    }

    private func handleAuthorizationResult(result: GIDSignInResult?, error: Error?) {
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

    func extractTextFromGoogleDrive(driveUrl: String) async {
        self.isExtracting = true
        self.extractionError = nil

        guard !driveUrl.isEmpty else {
            self.extractionError = "Please enter a Google Drive URL"
            self.isExtracting = false
            return
        }

        // Extract file ID from Google Drive URL
        guard let fileId = extractFileIdFromUrl(driveUrl) else {
            self.extractionError = "Invalid Google Drive URL format"
            self.isExtracting = false
            return
        }

        guard let user = GIDSignIn.sharedInstance.currentUser else {
            self.extractionError = "Not authenticated with Google Drive"
            self.isExtracting = false
            return
        }

        // Get the access token (tokens are automatically refreshed by Google Sign-In SDK)
        let accessToken = user.accessToken.tokenString

        // Determine document type and appropriate MIME type for export
        let mimeType = getMimeTypeForUrl(driveUrl)

        // Use Google Drive API to export the document
        let exportUrl =
            "https://www.googleapis.com/drive/v3/files/\(fileId)/export?mimeType=\(mimeType)"

        guard let url = URL(string: exportUrl) else {
            self.extractionError = "Invalid export URL"
            self.isExtracting = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            self.isExtracting = false

            guard let httpResponse = response as? HTTPURLResponse else {
                self.extractionError = "Invalid response"
                return
            }

            if httpResponse.statusCode == 404 {
                // File not found or no permission - trigger Google Drive picker
                self.pendingExtractionUrl = driveUrl
                await self.showGoogleDrivePicker()
                return
            } else if httpResponse.statusCode == 403 {
                var extractionError =
                    "Access denied. Make sure the document is publicly accessible or you have permission to view it."
                if let errorMessage = String(data: data, encoding: .utf8) {
                    extractionError += "\n\nError message: \(errorMessage)"
                }
                self.extractionError = extractionError
                return
            } else if httpResponse.statusCode != 200 {
                var extractionError =
                    "Failed to retrieve document (HTTP \(httpResponse.statusCode))"
                if let errorMessage = String(data: data, encoding: .utf8) {
                    extractionError += "\n\nError message: \(errorMessage)"
                }
                self.extractionError = extractionError
                return
            }

            guard let text = String(data: data, encoding: .utf8) else {
                self.extractionError = "Failed to decode document content"
                return
            }

            if text.isEmpty {
                self.extractedText = "(Document appears to be empty)"
            } else {
                self.extractedText = text
            }
        } catch {
            self.extractionError = "Network error: \(error.localizedDescription)"
            self.isExtracting = false
        }
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

    private func showGoogleDrivePicker() async {
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
    }

    private func createPickerHTML(accessToken: String, clientId: String, apiKey: String) -> String {
        return """
            <!DOCTYPE html>
            <html>
                <head>
                    <title>Google Drive Picker</title>
                    <script src="https://apis.google.com/js/api.js"></script>
                    <script src="https://accounts.google.com/gsi/client"></script>
                    <style>
                        body {
                            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                            padding: 20px;
                            background-color: #f5f5f5;
                        }
                        .container {
                            text-align: center;
                            padding: 40px;
                        }
                        .button {
                            background-color: #4285f4;
                            color: white;
                            border: none;
                            padding: 12px 24px;
                            border-radius: 6px;
                            font-size: 16px;
                            cursor: pointer;
                            margin: 10px;
                        }
                        .button:hover {
                            background-color: #3367d6;
                        }
                        .message {
                            margin: 20px 0;
                            padding: 15px;
                            background-color: #e3f2fd;
                            border-radius: 6px;
                            color: #1976d2;
                        }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <h2>Google Drive File Access</h2>
                        <div class="message">
                            The file you're trying to access requires explicit permission. Please select the file from your Google Drive to grant access.
                        </div>
                        <button id="pick" class="button">Select File from Google Drive</button>
                        <button id="cancel" class="button" style="background-color: #666;">Cancel</button>
                        <div id="result"></div>
                    </div>

                    <script>
                        let accessToken = "\(accessToken)";
                        let clientId = "\(clientId)";
                        let pickerApiLoaded = false;

                        function onApiLoad() {
                            gapi.load("picker", onPickerApiLoad);
                        }

                        function onPickerApiLoad() {
                            pickerApiLoaded = true;
                            document.getElementById("pick").disabled = false;
                        }

                        function createPicker() {
                            if (pickerApiLoaded && accessToken) {
                                const picker = new google.picker.PickerBuilder()
                                    .addView(google.picker.ViewId.DOCS)
                                    .setOAuthToken(accessToken)
                                    .setDeveloperKey("\(apiKey)")
                                    .setAppId("\(clientId)")
                                    .setCallback(pickerCallback)
                                    .build();
                                picker.setVisible(true);
                            }
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

                        document.getElementById("pick").addEventListener("click", createPicker);
                        document.getElementById("pick").disabled = true;

                        document.getElementById("cancel").addEventListener("click", function () {
                            window.webkit.messageHandlers.pickerCancelled.postMessage({});
                        });

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
                await self.extractTextFromGoogleDrive(driveUrl: url)
            }
        }

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
