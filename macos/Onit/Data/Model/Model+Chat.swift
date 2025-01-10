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

            do {
                let chat: String
                if preferences.mode == .remote {
                    let images = await remoteImages
                    streamedResponse = ""
                    let onProgress: @Sendable (String) -> Void = { [weak self] text in
                        DispatchQueue.main.async {
                            self?.streamedResponse = text
                        }
                    }
                    let onComplete: @Sendable (String) -> Void = { [weak self] text in
                        DispatchQueue.main.async {
                            if let self = self {
                                self.streamedResponse = text
                                self.finishGeneration(text: text)
                            }
                        }
                    }
                    chat = try await client.chat(
                        text,
                        input: input,
                        model: preferences.model,
                        token: getTokenForModel(preferences.model ?? nil),
                        files: files,
                        images: images,
                        onProgress: onProgress,
                        onComplete: onComplete
                    )
                } else {
                    let images = await localImages
                    chat = try await client.localChat(
                        text, input: input, model: preferences.localModel, files: files, images: images
                    )
                    finishGeneration(text: chat)
                }
            } catch let error as FetchingError {
                print("Fetching Error: \(error.localizedDescription)")
                if case .forbidden(let message) = error {
                    setTokenIsValid(false)
                }
                if case .unauthorized = error {
                    setTokenIsValid(false)
                }
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

    func finishGeneration(text: String) {
        addChat(text)
        if let prompt = self.prompt {
            self.generationIndex = prompt.responses.count - 1
        }
        self.generationState = .generated
        setTokenIsValid(true)
    }
    
    func cancelGenerate() {
        generateTask?.cancel()
        generateTask = nil
        self.generationState = .idle
    }

    func setTokenIsValid(_ isValid: Bool) {
        if preferences.mode == .local { return }
        switch preferences.model?.provider {
        case .openAI:
            isOpenAITokenValidated = isValid
        case .anthropic:
            isAnthropicTokenValidated = isValid
        case .xAI:
            isXAITokenValidated = isValid
        case .none:
            break
        }
    }

    func getTokenForModel(_ model: AIModel?) -> String? {
        if let provider = model?.provider {
            switch provider {
            case .openAI:
                return openAIToken
            case .anthropic:
                return anthropicToken
            case .xAI:
                return xAIToken
            }
        }
        return nil
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
