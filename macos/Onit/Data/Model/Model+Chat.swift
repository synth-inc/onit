//
//  Model+Chat.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Defaults
import Foundation
import PostHog
import EventSource

extension OnitModel {
    func createAndSavePrompt() -> Prompt {
        // Create a new prompt

        // This would actually be a good place to do the images

        let prompt = Prompt(
            instruction: pendingInstruction, timestamp: .now, input: pendingInput,
            contextList: pendingContextList)

        // If there's no current chat, create one
        if currentChat == nil {
            currentChat = Chat(prompts: [], timestamp: .now)
            currentPrompts = []
            let modelContext = container.mainContext
            modelContext.insert(currentChat!)
        }

        // If there's a last prompt, set the prior and next prompts
        if let lastPrompt = currentChat?.prompts.last {
            prompt.priorPrompt = lastPrompt
            lastPrompt.nextPrompt = prompt
        }

        // Add the prompt to the current chat
        currentChat?.prompts.append(prompt)
        currentPrompts?.append(prompt)
        pendingInstruction = ""
        pendingInput = nil

        do {
            try container.mainContext.save()
        } catch {
            print(error.localizedDescription)
        }

        return prompt
    }

    func generate(_ prompt: Prompt) {
        cancelGenerate()
        generatingPrompt = prompt
        generatingPromptPriorState = prompt.generationState
        trackEventGeneration(prompt: prompt)

        generateTask = Task { [weak self] in
            guard let self = self else { return }

            prompt.generationState = .generating
            let curInstruction = prompt.instruction
            var filesHistory: [[URL]] = [prompt.contextList.files]
            var inputsHistory: [Input?] = [prompt.input]
            var imagesHistory: [[URL]] = [prompt.contextList.images]
            var instructionsHistory: [String] = [curInstruction]
            var autoContextsHistory: [[String: String]] = [prompt.contextList.autoContexts]
            var responsesHistory: [String] = []

            // Go through prior prompts and add them to the history
            var currentPrompt: Prompt? = prompt.priorPrompt
            while currentPrompt != nil {
                let response = currentPrompt!.responses[currentPrompt!.generationIndex]
                if response.type != .error {
                    instructionsHistory.insert(currentPrompt!.instruction, at: 0)
                    inputsHistory.insert(currentPrompt!.input, at: 0)
                    filesHistory.insert(currentPrompt!.contextList.files, at: 0)
                    imagesHistory.insert(currentPrompt!.contextList.images, at: 0)
                    autoContextsHistory.insert(currentPrompt!.contextList.autoContexts, at: 0)
                    responsesHistory.insert(
                        currentPrompt!.responses[currentPrompt!.generationIndex].text, at: 0)
                } else {
                    print("Skipping failed response from prior prompt.")
                }
                currentPrompt = currentPrompt!.priorPrompt
            }

            do {
                switch Defaults[.mode] {
                case .remote:
                    streamedResponse = ""
                    addPartialPrompt(prompt: prompt, instruction: curInstruction)
                    
                    let apiToken = getTokenForModel(Defaults[.remoteModel] ?? nil)
                    let asyncText = try await streamingClient.chatInStream(instructions: instructionsHistory,
                                                                           inputs: inputsHistory,
                                                                           files: filesHistory,
                                                                           images: imagesHistory,
                                                                           autoContexts: autoContextsHistory,
                                                                           responses: responsesHistory,
                                                                           model: Defaults[.remoteModel],
                                                                           apiToken: apiToken)
                    
                    for try await response in asyncText {
                        streamedResponse += response
                    }
                    
                    let response = Response(text: String(streamedResponse), type: .success)
                    updatePrompt(prompt: prompt, response: response, instruction: curInstruction)
                    setTokenIsValid(true)
                case .local:
                    // TODO implement history for local chat!
                    let chat = try await client.localChat(
                        instructions: instructionsHistory,
                        inputs: inputsHistory,
                        files: filesHistory,
                        images: imagesHistory,
                        autoContexts: autoContextsHistory,
                        responses: responsesHistory,
                        model: Defaults[.localModel]
                    )
                    let response = Response(text: chat, type:.success)
                    updatePrompt(prompt: prompt, response: response, instruction: curInstruction)
                    setTokenIsValid(true)
                }
            } catch let error as FetchingError {
                print("Fetching Error: \(error.localizedDescription)")
                if case .forbidden = error {
                    setTokenIsValid(false)
                }
                if case .unauthorized = error {
                    setTokenIsValid(false)
                }
                let response = Response(text: error.localizedDescription, type: .error)
                updatePrompt(prompt: prompt, response: response, instruction: curInstruction)
            } catch {
                print("Unexpected Error: \(error.localizedDescription)")
                let response = Response(text: error.localizedDescription, type: .error)
                updatePrompt(prompt: prompt, response: response, instruction: curInstruction)
            }
        }
    }
    
    /**
     * Track an event when user prompted
     * - parameter prompt: The current prompt
     */
    private func trackEventGeneration(prompt: Prompt) {
        let eventName = "user_prompted"
        var modelName = ""

        if Defaults[.mode] == .remote {
            if let model = Defaults[.remoteModel] {
                if let customProviderName = model.customProviderName {
                    modelName = "\(customProviderName)/\(model.displayName)"
                } else {
                    modelName = model.displayName
                }
            }
        } else {
            modelName = Defaults[.localModel] ?? ""
        }

        let eventProperties: [String: Any] = [
            "prompt_mode": Defaults[.mode].rawValue,
            "prompt_model": modelName,
        ]
        PostHogSDK.shared.capture(eventName, properties: eventProperties)
    }

    func cancelGenerate() {
        generateTask?.cancel()
        generateTask = nil
        if let curPrompt = generatingPrompt, let priorState = generatingPromptPriorState {
            curPrompt.generationState = priorState
        }
    }

    func setTokenIsValid(_ isValid: Bool) {
        if let provider = Defaults[.remoteModel]?.provider {
            setTokenIsValid(isValid, provider: provider)
        }
    }

    func setTokenIsValid(_ isValid: Bool, provider: AIModel.ModelProvider) {
        if Defaults[.mode] == .local { return }
        switch provider {
        case .openAI:
            Defaults[.isOpenAITokenValidated] = isValid
        case .anthropic:
            Defaults[.isAnthropicTokenValidated] = isValid
        case .xAI:
            Defaults[.isXAITokenValidated] = isValid
        case .googleAI:
            Defaults[.isGoogleAITokenValidated] = isValid
        case .deepSeek:
            Defaults[.isDeepSeekTokenValidated] = isValid
        case .custom:
            break  // TODO: KNA -
        }
    }

    func getTokenForModel(_ model: AIModel?) -> String? {
        if let provider = model?.provider {
            switch provider {
            case .openAI:
                return Defaults[.openAIToken]
            case .anthropic:
                return Defaults[.anthropicToken]
            case .xAI:
                return Defaults[.xAIToken]
            case .googleAI:
                return Defaults[.googleAIToken]
            case .deepSeek:
                return Defaults[.deepSeekToken]
            case .custom:
                return nil  // TODO: KNA -
            }
        }
        return nil
    }
    
    func addPartialPrompt(prompt: Prompt, instruction: String) {
        prompt.priorInstructions.append(instruction)
        prompt.responses.append(Response.partial)
        prompt.generationIndex = (prompt.responses.count - 1)
        prompt.generationState = .done
        
        generatingPrompt = nil
        generatingPromptPriorState = nil
    }
    
    func updatePrompt(prompt: Prompt, response: Response, instruction: String) {
        if let partialResponseIndex = prompt.responses.firstIndex(where: { $0.isPartial }) {
            prompt.responses.remove(at: partialResponseIndex)
            prompt.priorInstructions.removeLast()
        }
        
        prompt.priorInstructions.append(instruction)
        prompt.responses.append(response)
        prompt.generationIndex = (prompt.responses.count - 1)
        prompt.generationState = .done
        
        generatingPrompt = nil
        generatingPromptPriorState = nil
    }
}
