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
import SwiftData

extension OnitModel {
    func createAndSavePrompt() {
        let prompt = Prompt(
            instruction: pendingInstruction,
            timestamp: .now,
            input: pendingInput,
            contextList: pendingContextList
        )

        if currentChat == nil {
            Task { @MainActor in
                let systemPrompt: SystemPrompt
                do {
                    systemPrompt = try container.mainContext.fetch(FetchDescriptor<SystemPrompt>())
                            .first(where: { $0.id == Defaults[.systemPromptId] }) ?? SystemPrompt.outputOnly
                } catch {
                    systemPrompt = SystemPrompt.outputOnly
                }
                
                let systemPromptCopy = systemPrompt
                currentChat = Chat(systemPrompt: systemPromptCopy, prompts: [], timestamp: .now)
                currentPrompts = []
                SystemPromptState.shared.shouldShowSystemPrompt = false
                let modelContext = container.mainContext

                // Preventing crash for when unwrapping currentChat fails.
                guard let chat = currentChat else { return }
                modelContext.insert(chat)
                
                finishPromptCreation(prompt)
            }
        } else {
            finishPromptCreation(prompt)
        }
    }
    
    private func finishPromptCreation(_ prompt: Prompt) {
        if let lastPrompt = currentChat?.prompts.last {
            prompt.priorPrompt = lastPrompt
            lastPrompt.nextPrompt = prompt
        }

        currentChat?.prompts.append(prompt)
        currentPrompts?.append(prompt)
        pendingInstruction = ""
        pendingInput = nil

        do {
            try container.mainContext.save()
        } catch {
            print(error.localizedDescription)
        }
        
        generate(prompt)
    }

    func generate(_ prompt: Prompt) {
        cancelGenerate()
        
        let systemPrompt = currentChat?.systemPrompt ?? SystemPrompt.outputOnly
        
        generatingPrompt = prompt
        generatingPromptPriorState = prompt.generationState
        trackEventGeneration(prompt: prompt)

        generateTask = Task { [systemPrompt, weak self] in
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
            let currentModelName = Defaults[.mode] == .local ? Defaults[.localModel] ?? "" : Defaults[.remoteModel]?.displayName ?? ""
            var currentPrompt: Prompt? = prompt.priorPrompt
            while currentPrompt != nil {
                if let generationIndex = currentPrompt?.generationIndex,
                   let responseCount = currentPrompt?.responses.count,
                   generationIndex >= 0,
                   generationIndex < responseCount {
                    let response = currentPrompt!.responses[generationIndex]
                    
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
                } else {
                    print("Skipping index out of bounds for prior prompt.")
                }
                
                currentPrompt = currentPrompt?.priorPrompt
            }

            do {
                guard instructionsHistory.count == inputsHistory.count,
                      inputsHistory.count == filesHistory.count,
                      filesHistory.count == imagesHistory.count,
                      imagesHistory.count == autoContextsHistory.count,
                      autoContextsHistory.count == responsesHistory.count + 1 else {
                    throw FetchingError.invalidRequest(
                        message:
                            "Mismatched array lengths: instructions, inputs, files, autoContexts and images must be the same length, and one longer than responses."
                    )
                }

                streamedResponse = ""
                
                switch Defaults[.mode] {
                case .remote:
                    guard let model = Defaults[.remoteModel] else {
                        throw FetchingError.invalidRequest(message: "Model is required")
                    }
                    let apiToken = getTokenForModel(model)
                    
                    if shouldUseStream(model) {
                        addPartialPrompt(prompt: prompt, instruction: curInstruction)
                        
                        let asyncText = try await streamingClient.chat(systemMessage: systemPrompt.prompt,
                                                                       instructions: instructionsHistory,
                                                                       inputs: inputsHistory,
                                                                       files: filesHistory,
                                                                       images: imagesHistory,
                                                                       autoContexts: autoContextsHistory,
                                                                       responses: responsesHistory,
                                                                       model: model,
                                                                       apiToken: apiToken)
                        for try await response in asyncText {
                            streamedResponse += response
                        }
                    } else {
                        streamedResponse = try await client.chat(systemMessage: systemPrompt.prompt,
                                                                 instructions: instructionsHistory,
                                                                 inputs: inputsHistory,
                                                                 files: filesHistory,
                                                                 images: imagesHistory,
                                                                 autoContexts: autoContextsHistory,
                                                                 responses: responsesHistory,
                                                                 model: model,
                                                                 apiToken: apiToken)
                    }
                case .local:
                    guard let model = Defaults[.localModel] else {
                        throw FetchingError.invalidRequest(message: "Model is required")
                    }
                    
                    if Defaults[.streamResponse].local {
                        addPartialPrompt(prompt: prompt, instruction: curInstruction)
                        
                        let asyncText = try await streamingClient.localChat(systemMessage: systemPrompt.prompt,
                                                                            instructions: instructionsHistory,
                                                                            inputs: inputsHistory,
                                                                            files: filesHistory,
                                                                            images: imagesHistory,
                                                                            autoContexts: autoContextsHistory,
                                                                            responses: responsesHistory,
                                                                            model: model)
                        for try await response in asyncText {
                            streamedResponse += response
                        }
                    } else {
                        streamedResponse = try await client.localChat(systemMessage: systemPrompt.prompt,
                                                                      instructions: instructionsHistory,
                                                                      inputs: inputsHistory,
                                                                      files: filesHistory,
                                                                      images: imagesHistory,
                                                                      autoContexts: autoContextsHistory,
                                                                      responses: responsesHistory,
                                                                      model: model)
                    }
                }
                
                let response = Response(text: String(streamedResponse), type: .success, model: currentModelName)
                updatePrompt(prompt: prompt, response: response, instruction: curInstruction)
                setTokenIsValid(true)
            } catch let error as FetchingError {
                print("Fetching Error: \(error.localizedDescription)")
                if case .forbidden = error {
                    setTokenIsValid(false)
                }
                if case .unauthorized = error {
                    setTokenIsValid(false)
                }
                let response = Response(text: error.localizedDescription, type: .error, model: currentModelName)
                updatePrompt(prompt: prompt, response: response, instruction: curInstruction)
            } catch {
                print("Unexpected Error: \(error.localizedDescription)")
                let response = Response(text: error.localizedDescription, type: .error, model: currentModelName)
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
            "accessibility_enabled": FeatureFlagManager.shared.accessibility
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
        case .perplexity:
            Defaults[.isPerplexityTokenValidated] = isValid
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
            case .perplexity:
                return Defaults[.perplexityToken]
            case .custom:
                return nil  // TODO: KNA -
            }
            
        }
        return nil
    }
    
    func shouldUseStream(_ aiModel: AIModel) -> Bool {
        switch aiModel.provider {
        case .openAI:
            return Defaults[.streamResponse].openAI
        case .anthropic:
            return Defaults[.streamResponse].anthropic
        case .xAI:
            return Defaults[.streamResponse].xAI
        case .googleAI:
            return Defaults[.streamResponse].googleAI
        case .deepSeek:
            return Defaults[.streamResponse].deepSeek
        case .perplexity:
            return Defaults[.streamResponse].perplexity
        case .custom:
            guard let providerId = aiModel.customProviderName else {
                return false
            }
            return Defaults[.streamResponse].customProviders[providerId] ?? false
        }
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
