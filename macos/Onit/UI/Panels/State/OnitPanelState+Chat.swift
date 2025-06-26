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
                let trackedWindow = self.foregroundWindow
                
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
        generationStopped = false
        
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

                // Determine web search strategy
                let webSearchEnabled = Defaults[.webSearchEnabled]
                let localWebSearchAllowed = Defaults[.mode] != .local || Defaults[.allowWebSearchInLocalMode]
                let useWebSearch = webSearchEnabled && localWebSearchAllowed && isNewInstruction

                var hasValidProviderSearchToken = false
                var onitSupportsSearchProvider = false
                if Defaults[.mode] == .remote, let model = Defaults[.remoteModel] {
                    let apiToken = TokenValidationManager.getTokenForModel(model)
                    let hasValidToken = apiToken?.isEmpty == false
                    hasValidProviderSearchToken = hasValidToken && (model.provider == .openAI || model.provider == .anthropic)

                    let providers = try? await FetchingClient().getChatSearchProviders()

                    if let providers = providers {
                        let provider = model.provider.rawValue
                        onitSupportsSearchProvider = providers.contains(where: { $0.lowercased() == provider })
                    }
                }

                let tavilyCostSavingMode = Defaults[.tavilyCostSavingMode]
                let useTavilySearch = useWebSearch && !hasValidProviderSearchToken && (tavilyCostSavingMode || !onitSupportsSearchProvider)

                // Perform client-side web search with Tavily if available
                if useTavilySearch {
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
                            apiToken: apiToken,
                            includeSearch: (useWebSearch && !useTavilySearch) ? true : nil)
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
                            apiToken: apiToken,
                            includeSearch: (useWebSearch && !useTavilySearch) ? true : nil)
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

    func stopGeneration() {
        guard let prompt = generatingPrompt else { return }
        generationStopped = true
        cancelGenerate()
        
        pendingInstruction = prompt.instruction
        textFocusTrigger.toggle()

        if FeatureFlagManager.shared.stopMode == .removePartial { removePartialResponse(prompt: prompt) }
        generatingPrompt = nil
    }
    
    func removePartialResponse(prompt: Prompt) {
        // If the prompt already has a response, we can just remove the last, partial response.
        if prompt.responses.count > 1, let lastResponse = prompt.responses.last, let lastInstruction = prompt.priorInstructions.last {
            prompt.removeLastResponse()  // Use safe removal method
            prompt.priorInstructions.removeLast()
            do {
                try container.mainContext.save()
            } catch {
                // Reset if it fails.
                prompt.responses.append(lastResponse)
                prompt.priorInstructions.append(lastInstruction)
                prompt.generationIndex = (prompt.responses.count - 1)
            }
        } else {
            // Otherwise, we need to remove the entire prompt.
            if let index = currentChat?.prompts.firstIndex(where: { $0.id == prompt.id }) {
                currentChat?.prompts.remove(at: index)
            }
            if let curIndex = currentPrompts?.firstIndex(where: { $0.id == prompt.id }) {
                currentPrompts?.remove(at: curIndex)
            }
            container.mainContext.delete(prompt)
            do {
                try container.mainContext.save()
                // Reset the nextPrompt/priorPrompt links, to account for the removed prompt. We only want to do this if the save succeeded.
                if let chatPrompts = currentChat?.prompts {
                    for existingPrompt in chatPrompts {
                        if existingPrompt.nextPrompt?.id == prompt.id {
                            existingPrompt.nextPrompt = prompt.nextPrompt
                        }
                        if existingPrompt.priorPrompt?.id == prompt.id {
                            existingPrompt.priorPrompt = prompt.priorPrompt
                        }
                    }
                }
            } catch {
                // If save fails, let's restore the partial prompt to prevent weird states.
                container.mainContext.rollback()
                if let chat = currentChat {
                    chat.prompts.append(prompt)
                    currentPrompts?.append(prompt)
                }
            }
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
        // TODO could this cause isues where the generation index is beyond the length of responses?
        if let partialResponseIndex = prompt.responses.firstIndex(where: { $0.isPartial }) {
            prompt.responses.remove(at: partialResponseIndex)
        }
        // We don't need to add the response if the generation was stopped we're removing the partial responses.
        if generationStopped == false || FeatureFlagManager.shared.stopMode != .removePartial {
            prompt.responses.append(response)
            prompt.generationState = .done
            do { try container.mainContext.save() } catch {
                container.mainContext.rollback()
                print("replacePartialResponse - Save failed!")
            }
        }
    }
    
    func sendAction(accountId: Int?) {
        if websiteUrlsScrapeQueue.isEmpty && windowContextTasks.isEmpty {
            let inputText = (pendingInstruction).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !inputText.isEmpty else { return }
            createAndSavePrompt(accountId: accountId)
        }
    }
}
