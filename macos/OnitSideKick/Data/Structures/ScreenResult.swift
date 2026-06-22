//
//  ScreenResult.swift
//  Onit
//
//  Created by Kévin Naudin on 22/01/2025.
//

import Foundation

struct ScreenResult {
    struct UserInteractions {
        var selectedText: String?
        var input: String?
    }

    var elapsedTime: String?
    var applicationName: String?
    var applicationTitle: String?
    var userInteraction: UserInteractions = .init()
    var others: [String: String]?
    var errorMessage: String?  // Renamed field for error message
    var errorCode: Int32?
    var appBundleUrl: URL?
    
    init(
        elapsedTime: String? = nil,
        applicationName: String? = nil,
        applicationTitle: String? = nil,
        userInteraction: UserInteractions = UserInteractions(),
        others: [String: String]? = nil,
        errorMessage: String? = nil,
        errorCode: Int32? = nil,
        appBundleUrl: URL? = nil
    ) {
        self.elapsedTime = elapsedTime
        self.applicationName = applicationName
        self.applicationTitle = applicationTitle
        self.userInteraction = userInteraction
        self.others = others
        self.errorMessage = errorMessage
        self.errorCode = errorCode
        self.appBundleUrl = appBundleUrl
    }
} 