//
//  String+Localized.swift
//  Onit
//
//  Created by Loyd Kim on 1/8/25.
//

import Foundation

extension String {
    /// Returns localized string using user's preferred language, found in `Defaults.translationSourceLanguageCode`, rather than system locale.
    @MainActor
    static func localized(
        _ key: String,
        table: String? = nil,
        comment: String = ""
    ) -> String {
        return NSLocalizedString(
            key,
            tableName: table,
            bundle: LocalizationManager.shared.bundle,
            comment: comment
        )
    }

    /// Returns localized string with format arguments, using user's preferred language.
    @MainActor
    static func localized(
        _ key: String,
        table: String? = nil,
        _ arguments: CVarArg...
    ) -> String {
        let format = NSLocalizedString(
            key,
            tableName: table,
            bundle: LocalizationManager.shared.bundle,
            comment: ""
        )
        if arguments.isEmpty {
            return format
        }
        return String(format: format, arguments: arguments)
    }
}
