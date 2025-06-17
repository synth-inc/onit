//
//  GoogleDriveService.swift
//  Onit
//
//  Created by Jay Swanson on 6/17/25.
//

import Foundation
import GoogleSignIn
import SwiftUI

@MainActor
class GoogleDriveService: ObservableObject {
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

    func checkAuthorizationStatus() {
        guard let googleUser = GIDSignIn.sharedInstance.currentUser else {
            self.isAuthorized = false
            self.userEmail = nil
            return
        }

        if let grantedScopes = googleUser.grantedScopes,
            grantedScopes.contains("https://www.googleapis.com/auth/drive.readonly")
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
                ["https://www.googleapis.com/auth/drive.readonly"],
                presenting: window,
                completion: completion
            )
        } else {
            GIDSignIn.sharedInstance.signIn(
                withPresenting: window,
                hint: nil,
                additionalScopes: ["https://www.googleapis.com/auth/drive.readonly"],
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

            if httpResponse.statusCode == 403 {
                var extractionError =
                    "Access denied. Make sure the document is publicly accessible or you have permission to view it."
                if let errorMessage = String(data: data, encoding: .utf8) {
                    extractionError += "\n\nError message: \(errorMessage)"
                }
                self.extractionError = extractionError
                return
            } else if httpResponse.statusCode != 200 {
                self.extractionError =
                    "Failed to retrieve document (HTTP \(httpResponse.statusCode))"
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
                    in: url, range: NSRange(location: 0, length: url.count))
            {
                let fileIdRange = Range(match.range(at: 1), in: url)!
                return String(url[fileIdRange])
            }
        }

        return nil
    }
}
