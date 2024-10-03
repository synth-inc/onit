//
//  Model.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI
import SageKit

@MainActor @Observable class Model: NSObject {
    var showMenuBarExtra = false
    var generationState: GenerationState = .idle
    var panel: CustomPanel?

    var generating: Bool {
        generationState == .generating
    }

    private var generateTask: Task<Void, Never>? = nil

    func generate() {
        cancelGenerate()
        generateTask = Task { [weak self] in
            guard let self = self else { return }
            self.generationState = .generating

            do {
                try await Task.sleep(for: .seconds(2))
                try Task.checkCancellation()
                self.generationState = .generated("Hello, world!")
            } catch {
                if Task.isCancelled {
                    self.generationState = .idle
                } else {
                    self.generationState = .error
                }
            }
        }
    }

    func cancelGenerate() {
        generateTask?.cancel()
        generateTask = nil
    }
}

enum GenerationState: Equatable {
    case idle
    case generating
    case generated(String)
    case error
}

private struct ModelEnvironmentKey: EnvironmentKey {
    @MainActor static var defaultValue: Model = .init()
}

extension EnvironmentValues {
    var model: Model {
        get { self[ModelEnvironmentKey.self] }
        set { self[ModelEnvironmentKey.self] = newValue }
    }
}
