//
//  Model+Chat.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

extension OnitModel {
    func createAndSavePrompt() -> Prompt {
        // Create a new prompt
        
        // This would actually be a good place to do the images
        
        let prompt = Prompt(instruction: pendingInstruction, timestamp: .now, input: pendingInput, contextList: pendingContextList)

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
        
        generateTask = Task { [weak self] in
            guard let self = self else { return }

            
            prompt.generationState = .generating
            let curInstruction = prompt.instruction
            var filesHistory : [[URL]] = [prompt.contextList.files]
            var inputsHistory : [Input?] = [prompt.input]
            var imagesHistory : [[URL]] = [prompt.contextList.images]
            var instructionsHistory: [String] = [curInstruction]
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
                    responsesHistory.insert(currentPrompt!.responses[currentPrompt!.generationIndex].text, at: 0)
                } else {
                    print("Skipping failed response from prior prompt.")
                }
                currentPrompt = currentPrompt!.priorPrompt
            }
            
            do {
                let chat: String
                if preferences.mode == .remote {
                    // chat(instructions: [String], inputs: [Input?], files: [[URL]], images[[URL]], responses: [String], model: AIModel?, apiToken: String?)
                    chat = try await client.chat(
                        instructions: instructionsHistory,
                        inputs: inputsHistory.map { _ in nil }, // Add back in inputs once we have accessibility
                        files: filesHistory,
                        images: imagesHistory,
                        responses: responsesHistory,
                        model: preferences.model,
                        apiToken: getTokenForModel(preferences.model ?? nil)
                    )
                } else {
                    // TODO implement history for local chat!
                    chat = try await client.localChat(
                        instructions: instructionsHistory,
                        inputs: inputsHistory.map { _ in nil },
                        files: filesHistory,
                        images: imagesHistory,
                        responses: responsesHistory,
                        model: preferences.localModel
                    )
                }

                let response = Response(text: chat, type:.success)
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
                let response = Response(text: error.localizedDescription, type:.error)
                updatePrompt(prompt: prompt, response: response, instruction: curInstruction)
            } catch {
                print("Unexpected Error: \(error.localizedDescription)")
                let response = Response(text: error.localizedDescription, type:.error)
                updatePrompt(prompt: prompt, response: response, instruction: curInstruction)
            }

            generatingPrompt = nil
            generatingPromptPriorState = nil
        }
    }

    func cancelGenerate() {
        generateTask?.cancel()
        generateTask = nil
        if let curPrompt = generatingPrompt, let priorState = generatingPromptPriorState {
            curPrompt.generationState = priorState
        }
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
    
    func updatePrompt(prompt: Prompt, response: Response, instruction: String) {
        prompt.priorInstructions.append(instruction)
        prompt.responses.append(response)
        prompt.generationIndex = (prompt.responses.count - 1)
        prompt.generationState = .done
    }
}
