//
//  Model+Chat.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

extension OnitModel {
    func save(_ text: String) {
        // Create a new prompt
        let prompt = Prompt(input: input, text: text, timestamp: Date())
        
        // If there's no current chat, create one
        if currentChat == nil {
            currentChat = Chat()
            let modelContext = container.mainContext
            modelContext.insert(currentChat!)
        }
        
        // Add the prompt to the current chat
        currentChat?.prompts.append(prompt)
        
        do {
            try container.mainContext.save()
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

            let response = self.updateYouSaid(text: text)
            instructions = ""

            do {
                let chat: String
                if preferences.mode == .remote {
                    let images = await remoteImages
                    chat = try await client.chat(
                        response, input: nil /*input*/, model: preferences.model, apiToken: getTokenForModel(preferences.model ?? nil), files: files, images: images
                    )
                } else {
                    let images = await localImages
                    chat = try await client.localChat(
                        response, input: nil /*input*/, model: preferences.localModel, files: files, images: images
                    )
                }
                addChat(chat)
                if let lastPrompt = currentChat?.prompts.last {
                    self.generationIndex = lastPrompt.responses.count - 1
                }
                self.generationState = .generated
                setTokenIsValid(true)
                
            } catch let error as FetchingError {
                print("Fetching Error: \(error.localizedDescription)")
                if case .forbidden = error {
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
        guard let lastPrompt = currentChat?.prompts.last else {
            print("Tried to add chat with no prompts")
            return
        }
        let response = Response(text: chat)
        lastPrompt.responses.append(response)
    }

    func cancelGenerate() {
        generateTask?.cancel()
        generateTask = nil
        self.generationState = .idle
    }

    func setTokenIsValid(_ isValid: Bool) {
        if let provider = preferences.model?.provider {
            setTokenIsValid(isValid, provider: provider)
        }
    }

    func setTokenIsValid(_ isValid: Bool, provider: AIModel.ModelProvider) {
        if preferences.mode == .local { return }
        switch provider {
        case .openAI:
            isOpenAITokenValidated = isValid
        case .anthropic:
            isAnthropicTokenValidated = isValid
        case .xAI:
            isXAITokenValidated = isValid
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
