//
//  Model+Chat.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

extension OnitModel {
    func generate(_ text: String) {
        cancelGenerate()
        generateTask = Task { [weak self] in
            guard let self = self else { return }

            self.generationState = .generating
            let files = context.files

            do {
                let chat = try await client.chat(text, input: input, model: preferences.model, files: files)
                self.generationState = .generated(chat)
            } catch let error as FetchingError {
                print("Fetching Error: \(error.localizedDescription)")
                self.generationState = .error(error)
            } catch {
                print("Unexpected Error: \(error.localizedDescription)")
                self.generationState = .error(.networkError(error))
            }
        }
    }

    func cancelGenerate() {
        generateTask?.cancel()
        generateTask = nil
        self.generationState = .idle
    }
}
