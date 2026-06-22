//
//  LanguageHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 12/29/25.
//

import Defaults
import Foundation

struct LanguageHelpers {
    /// e.g., "English", "French", "Japanese"
    static var currentLanguageName: String {
        guard let languageCode = Locale.current.language.languageCode?.identifier else {
            return NSLocalizedString("Unknown", tableName: "Settings", comment: "")
        }
        return Locale.current.localizedString(forLanguageCode: languageCode) ?? languageCode
    }
    
    /// e.g., "en", "fr", "ja"
    static var currentLanguageCode: String? {
        Locale.current.language.languageCode?.identifier
    }
    
    /// e.g., "US", "FR", "JP"
    static var currentRegionCode: String? {
        Locale.current.region?.identifier
    }
    
    /// Returns all values in Settings → General → Language & Region → Preferred Languages
    static var preferredLanguages: [String] {
        Locale.preferredLanguages
    }
    
    /// Iterates through `preferredLanguages` and translates them into language codes (e.g., "en", "fr", "ja")
    static var preferredLanguageCodes: [String] {
        var alreadyTranslatedLanguageCodes = Set<String>()
        
        return self.preferredLanguages.compactMap { preferredLanguage in
            let locale = Locale(identifier: preferredLanguage)
            let languageCode = locale.language.languageCode?.identifier
            
            guard let languageCode = languageCode,
                  !alreadyTranslatedLanguageCodes.contains(languageCode)
            else {
                return nil
            }
            
            alreadyTranslatedLanguageCodes.insert(languageCode)
            
            return languageCode
        }
    }
    
    static var sourceLanguageCodes: [String] {
        if let buildLanguageCode = Defaults[.translationBuildLanguageCode],
           buildLanguageCode.lowercased() != "en"
        {
            return [buildLanguageCode, "en"]
        } else {
            return ["en"]
        }
    }
    
    /// Returns the display name for a language code, localized to the specified locale.
    /// e.g., with French locale: "en" → "Anglais", "fr" → "Français"
    /// e.g., with English locale: "en" → "English", "fr" → "French"
    static func getLanguageCodeDisplayName(
        for languageCode: String,
        locale: Locale = .current
    ) -> String {
        let localeLanguageCode = Locale(identifier: languageCode).language.languageCode?.identifier ?? languageCode
        let displayName = locale.localizedString(forLanguageCode: localeLanguageCode)

        return displayName ?? languageCode
    }

    /// Returns the display name for a language code, localized to the user's preferred app language.
    /// Use this version in SwiftUI views for dynamic localization.
    @MainActor
    static func getLocalizedLanguageCodeDisplayName(for languageCode: String) -> String {
        let preferredLanguage = LocalizationManager.shared.currentLanguage
        let locale = Locale(identifier: preferredLanguage)
        return getLanguageCodeDisplayName(for: languageCode, locale: locale)
    }
}
