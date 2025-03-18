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
                modelContext.insert(currentChat!)
                
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
            
            let histories = self.getHistories(for: prompt)
            let filesHistory = histories.files
            let inputsHistory = histories.inputs
            let imagesHistory = histories.images
            let instructionsHistory = histories.instructions
            let autoContextsHistory = histories.autoContexts
            let responsesHistory = histories.responses

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
                    let apiToken = self.getTokenForModel(model)
                    
                    if self.shouldUseStream(model) {
                        self.addPartialPrompt(prompt: prompt, instruction: curInstruction)
                        
                        let asyncText = try await self.streamingClient.chat(systemMessage: systemPrompt.prompt,
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
                        streamedResponse = try await self.client.chat(systemMessage: systemPrompt.prompt,
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
                        self.addPartialPrompt(prompt: prompt, instruction: curInstruction)
                        
                        let asyncText = try await self.streamingClient.localChat(systemMessage: systemPrompt.prompt,
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
                        streamedResponse = try await self.client.localChat(systemMessage: systemPrompt.prompt,
                                                                          instructions: instructionsHistory,
                                                                          inputs: inputsHistory,
                                                                          files: filesHistory,
                                                                          images: imagesHistory,
                                                                          autoContexts: autoContextsHistory,
                                                                          responses: responsesHistory,
                                                                          model: model)
                    }
                }
                
                let currentModelName = self.getCurrentModelName()
                let response = Response(text: String(streamedResponse), type: .success, model: currentModelName)
                self.updatePrompt(prompt: prompt, response: response, instruction: curInstruction)
                self.setTokenIsValid(true)
            } catch let error as FetchingError {
                print("Fetching Error: \(error.localizedDescription)")
                if case .forbidden = error {
                    self.setTokenIsValid(false)
                }
                if case .unauthorized = error {
                    self.setTokenIsValid(false)
                }
                let currentModelName = self.getCurrentModelName()
                let response = Response(text: error.localizedDescription, type: .error, model: currentModelName)
                self.updatePrompt(prompt: prompt, response: response, instruction: curInstruction)
            } catch {
                print("Unexpected Error: \(error.localizedDescription)")
                let currentModelName = self.getCurrentModelName()
                let response = Response(text: error.localizedDescription, type: .error, model: currentModelName)
                self.updatePrompt(prompt: prompt, response: response, instruction: curInstruction)
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

    private func getCurrentModelName() -> String {
        if Defaults[.mode] == .remote {
            if let model = Defaults[.remoteModel] {
                if let customProviderName = model.customProviderName {
                    return "\(customProviderName)/\(model.displayName)"
                } else {
                    return model.displayName
                }
            }
        } else {
            return Defaults[.localModel] ?? ""
        }
        return ""
    }

    private func getHistories(for prompt: Prompt) -> (files: [[URL]], inputs: [Input?], images: [[URL]], instructions: [String], autoContexts: [[String: String]], responses: [String]) {
        var filesHistory = [prompt.contextList.files]
        var inputsHistory = [prompt.input]
        var imagesHistory = [prompt.contextList.images]
        var instructionsHistory = [prompt.instruction]
        var autoContextsHistory = [prompt.contextList.autoContexts]
        var responsesHistory: [String] = []
        
        var currentPrompt = prompt.priorPrompt
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
                }
            }
            currentPrompt = currentPrompt!.priorPrompt
        }
        
        return (filesHistory, inputsHistory, imagesHistory, instructionsHistory, autoContextsHistory, responsesHistory)
    }
}
