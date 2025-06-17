//
//  OnitPanelState+Chat.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Defaults
import Foundation
import PostHog
import EventSource
import SwiftData

extension OnitPanelState {
    
    func createAndSavePrompt(accountId: Int?) {
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
                            .first(where: { $0.id == systemPromptId }) ?? SystemPrompt.outputOnly
                } catch {
                    systemPrompt = SystemPrompt.outputOnly
                }
                
                let systemPromptCopy = systemPrompt
                let trackedWindow = AccessibilityNotificationsManager.shared.windowsManager.activeTrackedWindow
                currentChat = Chat(
                    systemPrompt: systemPromptCopy,
                    prompts: [],
                    timestamp: .now,
                    trackedWindow: trackedWindow,
                    accountId: accountId
                )
                currentPrompts = []
                systemPromptState.shouldShowSystemPrompt = false
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
        addPartialResponse(prompt: prompt)
        generatingPrompt = prompt
        generatingPromptPriorState = prompt.generationState
        
        AnalyticsManager.Chat.prompted(prompt: prompt)
        
        generateTask = Task { [systemPrompt, weak self] in
            guard let self = self else { return }

            prompt.generationState = .starting
            let curInstruction = prompt.instruction
            
            var filesHistory: [[URL]] = [prompt.contextList.files]
            var inputsHistory: [Input?] = [prompt.input]
            var imagesHistory: [[URL]] = [prompt.contextList.images]
            var instructionsHistory: [String] = [curInstruction]
            var autoContextsHistory: [[String: String]] = [prompt.contextList.autoContexts]
            var webSearchContextsHistory: [[(title: String, content: String, source: String, url: URL?)]] = [prompt.contextList.webSearchContexts]
            var responsesHistory: [String] = []

            // Go through prior prompts and add them to the history
            let currentModelName = Defaults[.mode] == .local ? Defaults[.localModel] ?? "" : Defaults[.remoteModel]?.displayName ?? ""
            var currentPrompt: Prompt? = prompt.priorPrompt
            while currentPrompt != nil {
                if let generationIndex = currentPrompt?.generationIndex,
                   let responseCount = currentPrompt?.responses.count,
                   generationIndex >= 0,
                   generationIndex < responseCount {
                    let response = currentPrompt!.sortedResponses[generationIndex]
                    
                    if response.type != .error {
                        instructionsHistory.insert(currentPrompt!.instruction, at: 0)
                        inputsHistory.insert(currentPrompt!.input, at: 0)
                        filesHistory.insert(currentPrompt!.contextList.files, at: 0)
                        imagesHistory.insert(currentPrompt!.contextList.images, at: 0)
                        autoContextsHistory.insert(currentPrompt!.contextList.autoContexts, at: 0)
                        webSearchContextsHistory.insert(currentPrompt!.contextList.webSearchContexts, at: 0)
                        responsesHistory.insert(
                            currentPrompt!.sortedResponses[currentPrompt!.generationIndex].text, at: 0)
                    } else {
                        print("Skipping failed response from prior prompt.")
                    }
                } else {
                    print("Skipping index out of bounds for prior prompt.")
                }
                
                currentPrompt = currentPrompt!.priorPrompt
            }

            do {
                guard instructionsHistory.count == inputsHistory.count,
                      inputsHistory.count == filesHistory.count,
                      filesHistory.count == imagesHistory.count,
                      imagesHistory.count == autoContextsHistory.count,
                      autoContextsHistory.count == responsesHistory.count + 1 else {
                    throw FetchingError.invalidRequest(
                        message: "Mismatched array lengths in chat history: instructions, inputs, files, autoContexts and images must be the same length, and one longer than responses."
                    )
                }

                streamedResponse = ""
                
                let isNewInstruction = !prompt.priorInstructions.dropLast().contains(prompt.instruction)
                if Defaults[.webSearchEnabled] && isNewInstruction {
                    isSearchingWeb[prompt.id] = true
                    let searchResults = await performWebSearch(query: curInstruction)
                    if !searchResults.isEmpty {
                        var updatedContextList = prompt.contextList
                        // Convert each WebSearchResult to a Context.webSearch object and add to pendingContextList
                        for searchResult in searchResults {
                            let searchResultURL = URL(string: searchResult.url)
                            // Check if the URL already exists in the contextList
                            if !updatedContextList.contains(where: { $0.url == searchResultURL }) {
                                updatedContextList.append(searchResult.toContext())
                                let webContext = (searchResult.title, searchResult.fullContent, searchResult.source, searchResultURL)
                                webSearchContextsHistory[webSearchContextsHistory.count - 1].append(webContext)
                            } else {
                                print("removing duplicate!")
                            }
                        }
                        prompt.contextList = updatedContextList // Reassign the entire array
                        // Tell SwiftData to process the changes
                        try container.mainContext.save()
                    }
                    isSearchingWeb[prompt.id] = false
                }
                
                switch Defaults[.mode] {
                case .remote:
                    guard let model = Defaults[.remoteModel] else {
                        throw FetchingError.invalidRequest(message: "Model is required")
                    }
                    let apiToken = TokenValidationManager.getTokenForModel(model)
                    let useOnitChat = apiToken == nil || apiToken == ""
                    
                    if useOnitChat || shouldUseStream(model) {
                        prompt.generationState = .streaming
                        let asyncText = try await streamingClient.chat(
                            systemMessage: systemPrompt.prompt,
                            instructions: instructionsHistory,
                            inputs: inputsHistory,
                            files: filesHistory,
                            images: imagesHistory,
                            autoContexts: autoContextsHistory,
                            webSearchContexts: webSearchContextsHistory,
                            responses: responsesHistory,
                            useOnitServer: useOnitChat,
                            model: model,
                            apiToken: apiToken)
                        for try await response in asyncText {
                            streamedResponse += response
                        }
                    } else {
                        prompt.generationState = .generating
                        streamedResponse = try await client.chat(
                            systemMessage: systemPrompt.prompt,
                            instructions: instructionsHistory,
                            inputs: inputsHistory,
                            files: filesHistory,
                            images: imagesHistory,
                            autoContexts: autoContextsHistory,
                            webSearchContexts: webSearchContextsHistory,
                            responses: responsesHistory,
                            model: model,
                            apiToken: apiToken)
                    }
                
                case .local:
                    guard let model = Defaults[.localModel] else {
                        throw FetchingError.invalidRequest(message: "Model is required")
                    }
                    
                    if Defaults[.streamResponse].local {
                        prompt.generationState = .streaming                        
                        let asyncText = try await streamingClient.localChat(
                            systemMessage: systemPrompt.prompt,
                            instructions: instructionsHistory,
                            inputs: inputsHistory,
                            files: filesHistory,
                            images: imagesHistory,
                            autoContexts: autoContextsHistory,
                            webSearchContexts: webSearchContextsHistory,
                            responses: responsesHistory,
                            model: model)
                        for try await response in asyncText {
                            streamedResponse += response
                        }
                    } else {
                        prompt.generationState = .generating
                        streamedResponse = try await client.localChat(
                            systemMessage: systemPrompt.prompt,
                            instructions: instructionsHistory,
                            inputs: inputsHistory,
                            files: filesHistory,
                            images: imagesHistory,
                            autoContexts: autoContextsHistory,
                            webSearchContexts: webSearchContextsHistory,
                            responses: responsesHistory,
                            model: model)
                    }
                }
                
                let response = Response(text: String(streamedResponse), instruction: curInstruction, type: .success, model: currentModelName)
                replacePartialResponse(prompt: prompt, response: response)
                TokenValidationManager.setTokenIsValid(true)
            } catch let error as FetchingError {
                print("Fetching Error: \(error.localizedDescription)")
                if case .forbidden = error {
                    TokenValidationManager.setTokenIsValid(false)
                }
                if case .unauthorized = error {
                    TokenValidationManager.setTokenIsValid(false)
                }
                let response = Response(text: error.localizedDescription, instruction: curInstruction, type: .error, model: currentModelName)
                replacePartialResponse(prompt: prompt, response: response)
            } catch {
                print("Unexpected Error: \(error.localizedDescription)")
                let response = Response(text: error.localizedDescription, instruction: curInstruction, type: .error, model: currentModelName)
                replacePartialResponse(prompt: prompt, response: response)
            }
            generatingPrompt = nil
        }
    }

    func cancelGenerate() {
        generateTask?.cancel()
        generateTask = nil
        if let curPrompt = generatingPrompt, let priorState = generatingPromptPriorState {
            curPrompt.generationState = priorState
        }
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
    
    func addPartialResponse(prompt: Prompt) {
        prompt.responses.append(Response.partial)
        prompt.priorInstructions.append(prompt.instruction)
        prompt.generationIndex = (prompt.responses.count - 1)
    }
    
    func replacePartialResponse(prompt: Prompt, response: Response) {
        // TODO could this cause isues where the generation index is beyond the lnegth of responses?
        if let partialResponseIndex = prompt.responses.firstIndex(where: { $0.isPartial }) {
            prompt.responses.remove(at: partialResponseIndex)
        }
        prompt.responses.append(response)
        prompt.generationState = .done
    }
    
    func sendAction(accountId: Int?) {
        if websiteUrlsScrapeQueue.isEmpty && windowContextTasks.isEmpty {
            let inputText = (pendingInstruction).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !inputText.isEmpty else { return }
            createAndSavePrompt(accountId: accountId)
        }
    }
}
