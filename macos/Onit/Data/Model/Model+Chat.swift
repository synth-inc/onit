//
//  Model+Chat.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

extension OnitModel {
    func save(_ text: String) {
        guard prompt == nil else { return }

        let prompt = Prompt(input: input, text: text, timestamp: Date())
        self.prompt = prompt
        let modelContext = container.mainContext
        modelContext.insert(prompt)
        do {
            try modelContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }

    func generate(_ text: String) {
        cancelGenerate()
        generateTask = Task { [weak self] in
            guard let self = self else { return }

            self.generationState = .generating
            let files = context.files
            let images = await remoteImages

            do {
                let chat : String
                if preferences.mode == .remote {
                    chat = try await client.chat(
                        text, input: input, model: preferences.model, files: files, images: images
                    )
                } else {
                    chat = try await client.localChat(
                        text, input: input, model: preferences.localModel, files: files, images: images
                    )
                }
                addChat(chat)
                if let prompt = self.prompt {
                    self.generationIndex = prompt.responses.count - 1
                }
                self.generationState = .generated
            } catch let error as FetchingError {
                print("Fetching Error: \(error.localizedDescription)")
                self.generationState = .error(error)
            } catch {
                print("Unexpected Error: \(error.localizedDescription)")
                self.generationState = .error(.networkError(error))
            }
        }
    }

    func addChat(_ chat: String) {
        guard let prompt else {
            print("Tried to add chat with nil promptID")
            return
        }
        let response = Response(text: chat)
        prompt.responses.append(response)
    }

    func cancelGenerate() {
        generateTask?.cancel()
        generateTask = nil
        self.generationState = .idle
    }

    var generation: String? {
        guard case .generated = generationState else { return nil }
        guard let prompt else { return nil }
        guard prompt.responses.count > generationIndex else { return nil }
        return prompt.responses[generationIndex].text
    }

    var generationCount: Int? {
        guard case .generated = generationState else { return nil }
        guard let prompt else { return nil }
        return prompt.responses.count
    }

    var canIncrementGeneration: Bool {
        guard case .generated = generationState else { return false }
        guard let prompt else { return false }
        return prompt.responses.count > generationIndex + 1
    }

    var canDecrementGeneration: Bool {
        return generationIndex > 0
    }
}
