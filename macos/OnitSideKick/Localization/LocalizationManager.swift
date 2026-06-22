//
//  LocalizationManager.swift
//  Onit
//
//  Created by Loyd Kim on 1/8/25.
//

import Combine
import Defaults
import Foundation

@MainActor
final class LocalizationManager: ObservableObject {
    // MARK: - Singleton

    static let shared = LocalizationManager()

    // MARK: - Initializer

    private init() {
        let sourceLanguageCode = Defaults[.translationSourceLanguageCode] ?? "en"

        self.currentLanguage = sourceLanguageCode
        self.bundle = Self.getBundle(for: sourceLanguageCode)
        setupObservers()
    }

    // MARK: - Published Properties

    @Published private(set) var currentLanguage: String
    @Published private(set) var bundle: Bundle

    // MARK: - States

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Functions
    
    private static func getBundle(for languageCode: String) -> Bundle {
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return Bundle.main
        }

        return bundle
    }

    private func setupObservers() {
        Defaults.publisher(.translationSourceLanguageCode)
            .map { $0.newValue ?? "en" }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sourceLanguageCode in
                self?.currentLanguage = sourceLanguageCode
                self?.bundle = Self.getBundle(for: sourceLanguageCode)
            }
            .store(in: &cancellables)
    }
}
